# SSH Key Pairs

## SSH Authentication Flow

![ssh-auth-flow excalidraw](https://user-images.githubusercontent.com/1337971/167814389-7de485a6-e5e6-4810-ad18-fb53781d5e25.svg)


## SSH Key Setup Overview

[Example GitHub SSH Setup]()

| S.No | Client   (Laptop)             | Remote Server (GitHub)                     |
| :--- | :---------------------------- | :----------------------------------------- |
| 1    | Generate the SSH Key Pair              | Provision rmote server with the Public Key |
|      | [ssh-keygen][1]                        |                                            |
| 2    | [Add Public Key][2]                    | [GitHub Keys][3]                           |
| 3    | Start SSH Agent                        |                                            |
|      | `eval "$(ssh-agent -s)"`               |                                            |
| 4    | Load Private Key to SSH Agent          |                                            |
|      | `ssh-add -K $PRIVATE_KEY`              |                                            |
| 5    | Check the setup                        |                                            |
|      | `ssh -i $PRIVATE_KEY user@github.com`  |                                            |

## Generating Keys

In Terminal Window

```bash

function ssh_key_gen(){
    KEY_PATH="keys"
    PRIVATE_KEY="$KEY_PATH/id_rsa"
    PUBLIC_KEY="$KEY_PATH/id_rsa.pub"
    if  [ ! -f $PRIVATE_KEY ] && [ ! -f $PUBLIC_KEY ] ;then
        vared -p 'GitHub EMail : ' -c EMAIL
        echo -e "Generating SSH Keys for $EMAIL"
        ssh-keygen -q -t rsa -N '' -f "$PRIVATE_KEY" -C "$EMAIL" <<<y 2>&1 >/dev/null
        echo -e "Applinf permissions to keys"
        chmod 400 "$PRIVATE_KEY" "$PUBLIC_KEY"
    else
        echo -e "SSH Keys Already Exists in $(realpath $KEY_PATH)"
    fi
}

ssh_key_gen

```

## Add Public Key to GitHub

1. Switch to direction `cd iaac/ssh-key-pairs`
1. Run `cat keys/id_rsa.pub `
1. Copy and Paste into [GitHub Keys][3]

> All SSH Keys get stored in $HOME/.ssh. For self study storing in the custom directory

## Signing Message & Validating It

In same Terminal window

```sh
vared -p 'Random Message : ' -c RANDOM_MESSAGE
echo $RANDOM_MESSAGE | ssh-keygen -Y sign -n file -f "$PRIVATE_KEY" > message.signed
```

## Validate Message

In same Terminal Window

```sh
echo $RANDOM_MESSAGE | ssh-keygen -Y check-novalidate -n file -f "$PUBLIC_KEY" -s message.signed
```

[1](#generating-keys)
[2](#add-public-key-to-gitbub)
[3](https://github.com/settings/keys)
