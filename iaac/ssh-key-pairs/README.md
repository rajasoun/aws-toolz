# SSH Key Pairs

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
