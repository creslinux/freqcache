# This file is utilized to generate a docker compose file
# based on all configuration files in the bots/config directory
# strategies need to be located in the bots/strategies directoryy

import os
import argparse
import json
from pathlib import Path
from pprint import pprint

parser = argparse.ArgumentParser(description='This script generates a docker compose file, based on the configuration files, found in the specified configuration directory. It assumes a certain directory structure to make sure all the path mappings are going to be valid')

parser.add_argument('--config', required=True, dest='config',
                    help='the directory containing all the configuration files')

parser.add_argument('--strategies', required=True, dest='strategy',
                    help='the directory containing your strategy file')

parser.add_argument('--image', required=False, dest='image',
                    help='the freqtrade image file to use', default="freqtrade")

args = parser.parse_args()


# list all configuration files, based on the json extension


for root, dirs, files in os.walk(args.config):
    for file in files:
        if file.endswith('.json'):
            print(file)
