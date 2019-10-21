# Tang (non-persistent) container

## What is tang?
Tang is the server-side implementation for "network-bound disk encryption". No keys from the client (usually clevis) are stored in tang, clevis just uses information derived from tang to encrypt/decrypt records (the LUKS key).
Further information about network-bound disk encryption can be found here: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Using_Network-Bound_Disk_Encryption.html
The tang implementation in this container is the Ubuntu-packaged version of https://github.com/latchset/tang

## Why in a container?
For simplicity and easy deployment. Tang should run in different infrastructure than the hosts to be protected. So a container is a versatile method to quickly deploy tang outside the core environment.

## Why is this container non-persistent?

Simply because I want to use it on [Heroku](https://www.heroku.com) and Heroku does not offer any persistent file-system storage. There is only very little persistent information required that can easily be stored in environment variables.

## Is this really secure?

Environment variables are the usual method to pass run-time information to containers and functions. Naturally (as soon as some kind of external access is required) this is also about secrets or tokens being passed. The good part is that the keys do not contain any information about the system. So you can't do anything with the keys itself, you still need the luksMetadata to derive the actual LUKS keys from it. This is better than storing the keys beside the system itself and maybe even better than manually entering the LUKS keys at boot time ... at least for public hosting, where a) the control channel where you enter the information may not be trusted and b) you can't really know if you give *your* system access to the key. (Evil Maid anyone?)

## Ok, I got it, what do I need to do

Run this container on the platform of you choice, passing the following ENV variables:

| variable       | content       | example  | Heroku value |
| -------------- |:-------------:| --------:| ------------:|
| PORT           | listening port| 80       | do not define, will be defined automatically |
| WHITELIST      | colon-separated CIDRs with hosts or networks that may access tang | 172.16.0.0/12:1.2.3.4/32 | nothing special |
| TRUSTED_PROXY  | colon-separated CIDRs with proxies that may hide the actual source      |   10.0.0.0/8:192.168.0.0/16 | 10.0.0.0/8 |
| TANG_LATEST_DK | JSON object containing *latest* deriveKey | {"alg":"ECMR","crv":"P-521", ... } | nothing special |
| TANG_LATEST_SV | JSON object containing *latest* sign,verify key | {"alg":"ES512","crv":"P-521", ... } | nothing special |
| TANG_OLD_*     | JSON object containing *old* keys | same as above | nothing special |

To get the initial keys you can install the `jose`package and runn the following commands:
`jose jwk gen -i '{"alg":"ES512"}'`
`jose jwk gen -i '{"alg":"ECMR"}'`
The json output of those is what you need to put into the TANG_LATEST_ ENV variables.

**TODO**: Script to rotate keys (using Heroku API or CLI)
