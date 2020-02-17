github_ssh
===

### Problem:

Securing your GitHub account and repos makes interacting with said repos, a little cumbersome; always requiring a password or token for verification before a push (or pull if repo is private).

The other solution is to add ssh keys to your account, which gives global access to **all** repos so you can push up anywhere to anything, unabated. Kind of like using a sledge hammer to hammer a nail.

The only other option is to generate ssh keys for each repo and then add them to the 'deploy keys' section in settings, for that specific repository. But how do you keep all those keys organized, and configure ssh to select the correct keys to use for that particular repository, and configure the local .git/config file of your repo to use the correct url?

### Solution:

- Clone this repo
- Add an alias to your ~/.bashrc file
    + `$ echo "alias https_to_ssh=~/path/to/script/https_to_ssh.sh" >> ~/.bashrc`
    + `$ source ~/.bashrc` -or- login/logout
        * If you're not sourcing your `~/.bashrc` file, you can add to your `~/.profile` file:
            - `if [ -s ~/.bashrc ]; then source ~/.bashrc; fi`
- Navigate to a repository you have on your machine that uses **https**.
    + `$ cd ~/some/repository/ && https_to_ssh` which will display help message for the script.


From here on out, all you have to do is:
- Clone your GitHub repo using the provided **https** url
- Navigate to the directory
- Run `$ https_to_ssh <category>`
- Add the pubkey that is printed to terminal to your repo's deploy keys
- Celebrate

### Script Options:

- There are a few default options (categories, really) provided in the script:
    + `github`
    + `personal`
    + `school`
    + `work`
- Each category will have it's own directory and, in a clean, organized manner, setup your ssh `config` files.