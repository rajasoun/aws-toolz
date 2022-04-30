# Getting Started

## Initial Setup

In Visual Studio Code, DevContainer Terminal Windows and follow the instructions
```sh
$ ci-cd config-prerequisite
```

### Configure gpg, pass and aws-vault

1. Generate a new GPG private key. (Optional if you already have a GPG key setup and trusted on the system)
   > Note: If you set a passphrase, you will be prompted to enter it.

   ```bash
   $ generate_gpg_keys #gpg2 --gen-key
   ```

2. Initialize the password-storage DB using the GPG `public` key ID or the associated email
   ```bash
   $ gpg2 --list-keys
   $ init_pass_store #similar to pass init <email_id> got from previous command
   ```
3. Configure aws-vault through wrapper
   ```bash
   $ aws-env
   $ exit
   ```

## Get AWS Bill for multiple accounts

To get bill of multiple AWS Accounts
   ```bash
   $ scripts/all_bills.sh
   ```
To get individual bill interactively
    ```bash
    $ aws-env scripts/bill.sh
    ```
