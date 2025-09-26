#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/men2985/server-installer.git"
INSTALL_DIR="/home/infra"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Este instalador debe ejecutarse como root. Usa 'sudo su -' y vuelve a intentarlo." >&2
    exit 1
  fi
}

detect_pkg_manager() {
  if command_exists apt-get; then
    PKG_MANAGER="apt"
  elif command_exists dnf; then
    PKG_MANAGER="dnf"
  elif command_exists yum; then
    PKG_MANAGER="yum"
  elif command_exists apk; then
    PKG_MANAGER="apk"
  elif command_exists pacman; then
    PKG_MANAGER="pacman"
  elif command_exists zypper; then
    PKG_MANAGER="zypper"
  else
    PKG_MANAGER=""
  fi
}

install_packages() {
  local packages=("$@")
  case "$PKG_MANAGER" in
    apt)
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
      ;;
    dnf)
      dnf install -y "${packages[@]}"
      ;;
    yum)
      yum install -y "${packages[@]}"
      ;;
    apk)
      apk update
      apk add --no-cache "${packages[@]}"
      ;;
    pacman)
      pacman -Sy --noconfirm "${packages[@]}"
      ;;
    zypper)
      zypper install -y "${packages[@]}"
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_base_dependencies() {
  detect_pkg_manager
  if [[ -z "$PKG_MANAGER" ]]; then
    echo "No se reconoció un gestor de paquetes compatible. Instala git, python3 y gettext manualmente." >&2
    exit 1
  fi

  case "$PKG_MANAGER" in
    apt)
      install_packages curl ca-certificates git python3 gettext-base
      ;;
    dnf)
      install_packages curl ca-certificates git python3 gettext
      ;;
    yum)
      install_packages curl ca-certificates git python3 gettext
      ;;
    apk)
      install_packages curl ca-certificates git python3 gettext
      ;;
    pacman)
      install_packages curl ca-certificates git python gettext
      ;;
    zypper)
      install_packages curl ca-certificates git python3 gettext-runtime
      ;;
  esac

  if ! command_exists python3; then
    echo "No se pudo instalar python3 automáticamente. Instálalo manualmente y vuelve a ejecutar." >&2
    exit 1
  fi

  if ! command_exists envsubst; then
    echo "No se pudo instalar envsubst automáticamente (paquete gettext). Instálalo manualmente y vuelve a ejecutar." >&2
    exit 1
  fi

  if ! command_exists git; then
    echo "No se pudo instalar git automáticamente. Instálalo manualmente y vuelve a ejecutar." >&2
    exit 1
  fi
}

install_docker_if_needed() {
  if command_exists docker; then
    return
  fi

  echo "Instalando Docker ..."
  local installed=0
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    if install_packages docker.io; then
      installed=1
    fi
  elif [[ "$PKG_MANAGER" == "dnf" || "$PKG_MANAGER" == "yum" ]]; then
    if install_packages docker; then
      installed=1
    fi
  elif [[ "$PKG_MANAGER" == "apk" ]]; then
    if install_packages docker; then
      installed=1
    fi
  elif [[ "$PKG_MANAGER" == "pacman" ]]; then
    if install_packages docker; then
      installed=1
    fi
  elif [[ "$PKG_MANAGER" == "zypper" ]]; then
    if install_packages docker; then
      installed=1
    fi
  fi

  if [[ $installed -eq 0 ]]; then
    curl -fsSL https://get.docker.com | sh
  fi

  if command_exists systemctl; then
    systemctl enable docker >/dev/null 2>&1 || true
    systemctl start docker >/dev/null 2>&1 || true
  elif command_exists service; then
    service docker start >/dev/null 2>&1 || true
  fi

  if ! command_exists docker; then
    echo "Docker no está disponible después de intentar instalarlo. Revisa la salida anterior." >&2
    exit 1
  fi
}

require_root
ensure_base_dependencies
install_docker_if_needed

# Clonar o actualizar repo
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "Actualizando repo en $INSTALL_DIR ..."
  git -C "$INSTALL_DIR" fetch --all --prune
  git -C "$INSTALL_DIR" checkout main
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Clonando repo en $INSTALL_DIR ..."
  mkdir -p "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Permisos
chmod +x install_core.sh uninstall.sh menu.sh reconfig.sh || true
chmod +x scripts/*.sh bootstrap/*.sh || true

# Ejecutar instalador real
exec ./install_core.sh
