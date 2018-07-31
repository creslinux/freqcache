###
# utility to quickly generate configurations files for a given strategy and a list of all pairs for a given marekt
##

import argparse
import json
from pathlib import Path
from pprint import pprint

##
# define our command line arguments

parser = argparse.ArgumentParser(description='This script splits all defined configurations pairs, '
                                             'into 1 config a pair. It will also update the DB file name')
parser.add_argument('--directory', required=False, dest='directory',
                    help='the directoy, where to store the generated configurations files', default="./")

parser.add_argument('--input', required=True, dest='input',
                    help='your input configuration, we are basing all the generated configurations of this')

args = parser.parse_args()

# load file as JSON
with open(args.input) as file:
    c = json.load(file)

    pairs = c['exchange']['pair_whitelist']
    for pair in pairs:
        configuration = c.copy()
        configuration['exchange']['pair_whitelist'] = [pair]

        # update the db url, if it's provided
        if 'db_url' in configuration:
            configuration['db_url'] = configuration['db_url'].replace(".sqlite",
                                                                      ".{}.sqlite".format(pair.replace("/", "_")))

        # otherwise generate a db url
        else:
            if 'strategy' in configuration:
                configuration['db_url'] = "sqlite:///user_data/data/config.{}.{}.sqlite".format(configuration['strategy'],
                                                                                 pair.replace("/", "_"))
            else:
                configuration['db_url'] = "sqlite:///user_data/data/config.{}.sqlite".format(pair.replace("/", "_"))

        # always disable telegram, since it won't work with mutliple parallel bots
        if 'telegram' in configuration:
            if 'enabled' in configuration['telegram']:
                configuration['telegram']['enabled'] = False

        # generate new file name
        outFile = args.input.replace(".json", ".{}.json".format(pair.replace("/", "_")))

        outFile = Path(args.directory).joinpath(Path(outFile).name)
        outFile.parent.mkdir(parents=True, exist_ok=True)

        with open(outFile, 'w') as fp:
            print("writing config file {}".format(outFile.absolute()))
            json.dump(configuration, fp, sort_keys=True,
                      indent=4)
