
resource "aws_instance" "RAG" {
  ami           = "ami-04b4f1a9cf54c11d0"  # Change based on your region
  instance_type = "g4dn.xlarge"
  root_block_device {
    volume_size = 100 
    volume_type = "gp3"
  }
  key_name      = "Karim_key"                 # Use your actual key pair
  security_groups = ["default"]
  connection {
    type        = "ssh"
    user        = "ubuntu"  # Change based on your AMI (e.g., "ec2-user" for Amazon Linux)
    private_key = file("~/.ssh/Karim_key.pem")  # Ensure correct path to your private key
    host        = self.public_ip
  }
  # provisioner "local-exec" {
  #   command = "echo ${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=$HOME/.ssh/Karim_key.pem >> inventory && sleep 10"
  # }
  # # provisioner "local-exec" {
  # #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory clone_repo.yml"
  # # }
  provisioner "file" {
    source      = "vm_script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh",
    ]
  }
  tags = {
    Name = "AnsibleManagedEC2"
  }
}

output "instance_ip" {
  value = aws_instance.RAG.public_ip
  description = "Public IP address of the EC2 instance"
}