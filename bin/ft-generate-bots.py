# This file is utilized to generate a docker compose file
# based on all configuration files in the bots/config directory
# strategies need to be located in the bots/strategies directoryy

import os
import argparse
import yaml
import json
from pathlib import Path
from pprint import pprint

parser = argparse.ArgumentParser(
    description='This script generates a docker compose file, based on the configuration files, found in the specified configuration directory. It assumes a certain directory structure to make sure all the path mappings are going to be valid')

parser.add_argument('--data', required=False, dest='data',
                    help='the directory where to store the database and datafiles', default="bots/data")

parser.add_argument('--config', required=False, dest='config', default="bots/config",
                    help='the directory containing all the configuration files')

parser.add_argument('--strategies', required=False, dest='strategy', default="bots/strategies",
                    help='the directory containing your strategy file')

parser.add_argument('--output', required=False, dest='output', help='the name of the generated file',
                    default="docker-compose.bot.yml")

parser.add_argument('--dns', required=False, dest='dns',
                    help='the dns server ip to use', default="10.99.7.249")

parser.add_argument('--image', required=False, dest='image',
                    help='the freqtrade image file to use', default="freqtrade")

parser.add_argument('--certificate', required=False, dest='cert',
                    help='the certificate file to use', default="ca.crt")

parser.add_argument('--network', required=False, dest='network',
                    help='the name of the network to use', default="freqcache_ft_network")
args = parser.parse_args()

# list all configuration files, based on the json extension

compose_file = {
    'version': '3',
    'services': {},
    "networks": {
        "default": {
            "external": {
                "name": args.network
            }
        }
    }
}

config_dir = Path(args.config).absolute()
strategy_file = Path(args.strategy).absolute()
data_file = Path(args.data).absolute()
cert_file = Path(args.cert).absolute()

print("file locations:")
print("config: {}".format(config_dir))
print("data: {}".format(data_file))
print("cert: {}".format(cert_file))
print()

for root, dirs, files in os.walk(config_dir):
    for file in files:
        if file.endswith('.json'):

            config_file = Path(args.config).joinpath(file).absolute()
            service = {
                "image": args.image,
                "dns": args.dns,
                "volumes": [
                    "{}:/freqtrade/config.json".format(config_file),
                    "{}:/freqtrade/user_data/strategies".format(strategy_file),
                    "{}:/freqtrade/user_data/data".format(data_file),
                    "{}:/freqtrade/ca.crt".format(cert_file)
                ],
                "environment": [
                    "SSL_CERT_FILE=/freqtrade/ca.crt",
                    "CURL_CA_BUNDLE=/freqtrade/ca.crt",
                    "REQUESTS_CA_BUNDLE=/freqtrade/ca.crt"
                ]

            }
            compose_file['services'].update({file: service})

output = Path(args.output).absolute()

print("writing result to: {}".format(output))
with open(output, 'w') as outfile:
    yaml.dump(compose_file, outfile)
