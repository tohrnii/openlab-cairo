import re
import inquirer
import pyfiglet
import subprocess

def install_image(image_repo):
    subprocess.run('docker pull {}'.format(image_repo).split())
    image_id = subprocess.run('docker images {}'.format(image_repo).split(), text=True, capture_output=True).stdout.split()[8]
    subprocess.run('docker run -it -d {}'.format(image_id).split())
    # container_id = subprocess.run('docker ps | grep {} | awk {}'.format(image_id, '{ print $1 }').split(), text=True, capture_output=True).stdout.split()
    # # subprocess.run('docker container ls'.split())
    # print(container_id)

def setup():
    docker_repos =  {'Lab-Colabfold': 'niklastr/lab-alphafold', 'Lab-Equibind': 'niklastr/lab-equibind'}
    questions = [
        inquirer.Checkbox('services',
            message="Which services do you want to run? (Press space to select all relevant options)",
            choices=['Lab-Colabfold', 'Lab-Equibind'],
        ),
    ]
    answers = inquirer.prompt(questions)
    for service in answers['services']:
        install_image(docker_repos[service])

def login():
    welcome_banner = pyfiglet.figlet_format("Welcome To OpenLab")
    print(welcome_banner)
    questions = [
        inquirer.List('login',
            message="Are you a new service provider?",
            choices=['Yes, Sign me up!', 'No, I already have an account']
        )
    ]
    answers = inquirer.prompt(questions)
    setup()

def main():
    login()

main()
