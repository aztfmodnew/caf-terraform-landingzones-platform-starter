if [ "${CODESPACES}" = "true" ]; then
    # Remove the default credential helper
    sudo sed -i -E 's/helper =.*//' /etc/gitconfig

    # Add one that just uses secrets available in the Codespace
    git config --global credential.helper '!f() { sleep 1; echo "username=${GITHUB_USER}"; echo "password=${GH_TOKEN}"; }; f'
fi

sudo chmod 666 /var/run/docker.sock || true
mkdir -p ~/.ssh
sudo cp -R /tmp/.ssh-localhost/* ~/.ssh 2>/dev/null || true
sudo chown -R $(whoami):$(whoami) ~ 2>/dev/null || true
sudo chmod 400 ~/.ssh/* 2>/dev/null || true

git config --global core.editor vim
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit install
fi

git config --global --add safe.directory /tf/caf
git config --global --add safe.directory /tf/caf/landingzones
git config --global --add safe.directory /tf/caf/landingzones/aztfmodnew
git config --global --add safe.directory /tf/caf/aztfmod
git config --global --add safe.directory /tf/caf/aztfmodnew

git config pull.rebase false

if [ ! -d /tf/caf/landingzones ]; then
  git clone --branch main https://github.com/aztfmodnew/caf-terraform-landingzones.git /tf/caf/landingzones
  sudo chmod +x /tf/caf/landingzones/templates/**/*.sh
fi
