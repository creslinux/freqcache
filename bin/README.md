# Usage:

The scripts in this folder are utilized to simplify the utilzation of the freqcache bot net.

### ft-split-config-file.py

This script is used to split one config file into N config files. N is defined by the numbers of currency pairs
in the whitelist.

It will also configure an unique database for each of these configuration files and disable the telgram apu.

#### Invoking it

```python

 python3 bin/ft-split-config-file.py --input bots/config/multitest.json --directory bots/config/generate
```
This will now generate the requested configuration files in the generate directory. which can than be specified as argument
for the ft-generate-bots.py script to generate a docker-compose file to launch all these bots.

#####Example output:
```python

writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.KMD_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.VIBE_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.PPT_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.PIVX_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.REP_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.OST_BTC.json
writing config file /Users/wohlgemuth/freqcache/bots/config/generate/multitest.SNM_BTC.json
```
### ft-generate-bots.py

This scripts utility is to easily generate a docker compose file for to launch 100s of bots. The idea behind it, is that 
you provided it with a directory containing all the wished configuration files.

Each launched bots name, will be the name of a configuration file.

```python
 python3 bin/ft-generate-bots.py --config bots/config/generate
```

The output is a docker compose file, with the name `docker-compose.bots.yml` by default.

##### Example output:

```python

python3 bin/ft-generate-bots.py --config bots/config/generate/
file locations:
config: /Users/wohlgemuth/freqcache/bots/config/generate
data: /Users/wohlgemuth/freqcache/bots/data
cert: /Users/wohlgemuth/freqcache/ca.crt

writing result to: /Users/wohlgemuth/freqcache/docker-compose.bot.yml
```

this file can now be launced with

```python
docker-compose -f docker-compose.bot.yml up
```

Which might take a couple of minutes, depending on your system. To launch all these bots.

```python
Creating freqcache_multitest.AION_BTC.json_1  ... 
Creating freqcache_multitest.VIBE_BTC.json_1  ...
Creating freqcache_multitest.GNT_BTC.json_1   ... 
Creating freqcache_multitest.MTL_BTC.json_1   ... 
Creating freqcache_multitest.RCN_BTC.json_1   ... 
Creating freqcache_multitest.LTC_BTC.json_1   ... 
Creating freqcache_multitest.STORM_BTC.json_1 ... 

```

Congratulations you are now the proud owner of a freqtrade bot net, to earn untold riches.