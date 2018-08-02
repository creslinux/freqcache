###
# utility to quickly generate configurations, based on a given configuration and a directories of strategies. It
# provides the functionality to copy all the strategies to custom directory as well
# or to strore them as BASE64 encoded version in the generated configs
##

import argparse
import json
import os
from base64 import urlsafe_b64encode
from pathlib import Path

##
# define our comncmand line arguments

parser = argparse.ArgumentParser(
    description='This script generates configurations based on all strategies in a directory')
parser.add_argument('--directory', required=False, dest='directory',
                    help='the directory, where to store the generated configurations files', default="./")

parser.add_argument('--strategies', required=True, dest='strategies',
                    help='location directory, where are all the strategies stored')

parser.add_argument('--embedded', required=False, dest='base64', action='store_true',
                    help='should the strategies be embedded as BASE64 encoded value '
                         'in the generated configuration files?')

parser.add_argument('--input', required=True, dest='input',
                    help='your input configuration, we are basing all the generated configurations of this')

args = parser.parse_args()

# load all strategies from the given directory
strategy_directory = args.strategies

# load file as JSON
with open(args.input) as input:
    c = json.load(input)

    # load all strategy files
    for root, dirs, files in os.walk(strategy_directory):
        for file in files:

            configuration = c.copy()
            if file.endswith('.py'):
                name = file.split(".")[0]

                if args.base64:
                    # encode the file as BASE64
                    with open(Path(strategy_directory).joinpath(file), 'r') as f:
                        content = f.read()
                        content = urlsafe_b64encode(bytes(content, 'utf-8')).decode('utf-8')
                        configuration['strategy'] = "{}:{}".format(name, content)

                else:
                    configuration['strategy'] = name

                if 'db_url' in configuration:
                    configuration['db_url'] = configuration['db_url'].replace(".sqlite",
                                                                              ".{}.sqlite".format(name))

                # always disable telegram, since it won't work with mutliple parallel bots
                if 'telegram' in configuration:
                    if 'enabled' in configuration['telegram']:
                        configuration['telegram']['enabled'] = False

                # generate new file name
                outFile = args.input.replace(".json", ".{}.json".format(name))

                outFile = Path(args.directory).joinpath(Path(outFile).name)
                outFile.parent.mkdir(parents=True, exist_ok=True)

                with open(outFile, 'w') as fp:
                    print("writing config file {}".format(outFile.absolute()))
                    json.dump(configuration, fp, sort_keys=True,
                              indent=4)
