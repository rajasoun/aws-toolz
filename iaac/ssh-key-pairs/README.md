# SSH Key Pairs

## SSH Authentication Flow

![ssh-auth-flow excalidraw](https://user-images.githubusercontent.com/1337971/167814389-7de485a6-e5e6-4810-ad18-fb53781d5e25.svg)


## SSH Key Setup Overview

| S.No | Client                        | Remote Server                              |
| :--- | :---------------------------- | :----------------------------------------- |
| 1.   | Generate the SSH Key Pair     | Provision rmote server with the Public Key |
|      | ssh-keygen                    |                                            |
| 2    | Start SSH Agent               |                                            |
|      | eval "$(ssh-agent -s)"        |                                            |
| 3    | Load Private Key to SSH Agent |                                            |
|      | ssh-add -K private_key        |                                            |
| 4    | ssh -F <ssh-config> host or   |                                            |
|      | ssh -i <private-key>user@ip   |                                            |


## Generating Keys

In Terminal Window

```sh
KEY_PATH="keys"
PRIVATE_KEY="$KEY_PATH/id_rsa"
PUBLIC_KEY="$KEY_PATH/id_rsa.pub"
vared -p 'EMail : ' -c EMAIL
echo -e "Generating SSH Keys for $EMAIL"
#ssh-keygen -q -t rsa -N '' -f "$PRIVATE_KEY" -C "$EMAIL" <<<y 2>&1 >/dev/null
ssh-keygen -q -t rsa -N '' -f "$PRIVATE_KEY" -C "$EMAIL" <<<y
```

## Signing Message & Validating It

In same Terminal window

```sh
MESSAGE="Hello, World"
echo $MESSAGE | ssh-keygen -Y sign -n file -f "$PRIVATE_KEY" > message.signed
```

## Validate Message

In same Terminal Window

```sh
echo $MESSAGE | ssh-keygen -Y check-novalidate -n file -f "$PUBLIC_KEY" -s message.signed
```