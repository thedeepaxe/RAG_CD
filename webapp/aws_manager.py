import os
import subprocess
from flask import Flask, render_template, jsonify, Response

app = Flask(__name__)

TERRAFORM_DIR = "/Users/karimfeki/Desktop/IMT/FiseA3/ProCOM/RAG_dev/RAG_CD"  # Change this path if needed
terraform_process = None  # Store the running Terraform process

# Function to run Terraform apply
def run_terraform():
    global terraform_process

    try:
        terraform_process = subprocess.Popen(
            ['terraform', 'apply', '-auto-approve'],
            cwd=TERRAFORM_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        for line in terraform_process.stdout:
            yield f"data: {line}\n\n"

        for line in terraform_process.stderr:
            yield f"data: {line}\n\n"

        terraform_process.wait()  # Wait for Terraform to complete

    except Exception as e:
        yield f"data: Error running Terraform: {str(e)}\n\n"

# Function to run Terraform destroy
def destroy_terraform():
    global terraform_process

    try:
        if terraform_process is not None:
            terraform_process.terminate()
            terraform_process.wait()

        destroy_process = subprocess.Popen(
            ['terraform', 'destroy', '-auto-approve'],
            cwd=TERRAFORM_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        for line in destroy_process.stdout:
            yield f"data: {line}\n\n"

        for line in destroy_process.stderr:
            yield f"data: {line}\n\n"

        destroy_process.wait()

    except Exception as e:
        yield f"data: Error running Terraform destroy: {str(e)}\n\n"

# New function to check Terraform state
def get_ec2_instance_info():
    try:
        # Get a list of resources from the Terraform state
        state_process = subprocess.Popen(
            ['terraform', 'state', 'list'],
            cwd=TERRAFORM_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, _ = state_process.communicate()

        if "aws_instance." in stdout:  # If an EC2 instance is found
            # Get its public IP
            ip_process = subprocess.Popen(
                ['terraform', 'output', '-raw', 'public_ip'],
                cwd=TERRAFORM_DIR,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            ip, _ = ip_process.communicate()

            return {"ec2_instance": {"public_ip": ip.strip()}}
        else:
            return {"ec2_instance": None}  # No EC2 instance found

    except Exception as e:
        return {"error": str(e)}

@app.route('/state', methods=['GET'])
def check_state():
    return jsonify(get_ec2_instance_info())

@app.route('/start', methods=['POST'])
def start_terraform():
    return Response(run_terraform(), content_type='text/event-stream')

@app.route('/destroy', methods=['POST'])
def destroy_infrastructure():
    return Response(destroy_terraform(), content_type='text/event-stream')

@app.route('/')
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)