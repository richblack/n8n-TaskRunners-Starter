# 指定 Terraform 需要的提供者 (Provider)
terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.13.0"
    }
  }
}

# 設定 Linode 提供者，token 將從變數傳入
provider "linode" {
  token = var.linode_token
}

# 定義一個變數來接收 Linode API Token
variable "linode_token" {
  type      = string
  sensitive = true
  description = "Your Linode API Token."
}

# 定義一個變數來接收伺服器的 root 密碼
variable "root_password" {
  type      = string
  sensitive = true
  description = "The root password for the new Linode instance."
}

# 定義一個變數來接收用於 SSH 登入的公鑰
variable "authorized_keys" {
  type        = list(string)
  description = "A list of public SSH keys to install on the server for the root user."
}

# 建立一個專用的防火牆
resource "linode_firewall" "n8n_firewall" {
  label = "n8n-firewall"
  
  # Inbound: 預設全部阻擋
  inbound_policy = "DROP"
  
  # Outbound: 預設全部允許
  outbound_policy = "ACCEPT"

  # 明確允許的 Inbound 規則
  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"] # 允許任何 IP 進行 SSH (您可以限制為您的 IP)
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  
}

# 建立一台 Linode 虛擬機實例
resource "linode_instance" "n8n_server" {
  label      = "n8n-supabase-psql-server"
  image      = "linode/ubuntu22.04" # 使用 Ubuntu 22.04 LTS
  region     = "ap-northeast"       # 您可以更換成您偏好的區域, e.g., us-central, eu-west
  type       = "g6-nanode-1"        # 這是最小的方案 (1GB RAM)，您可以根據需求調整
  
  root_pass = var.root_password
  authorized_keys = var.authorized_keys

  # 將此實例附加到我們建立的防火牆
  firewall_id = linode_firewall.n8n_firewall.id

  tags = ["n8n", "supabase", "docker"]
}

# 輸出新建立的伺服器的 IP 位址
output "instance_ip" {
  value = linode_instance.n8n_server.ip_address
  description = "The public IP address of the Linode instance."
}
