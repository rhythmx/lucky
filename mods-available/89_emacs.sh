logmsg emacs::debug loading emacs features

function install_spacemacs() {
	if ! which emacs >/dev/null; then
		echo "Emacs is not installed, attempting to install..."
		if which apt >/dev/null; then
			sudo apt install emacs
		fi
	fi
	if [ -d ~/.emacs.d ]; then
		echo ".emacs.d exists, NOT installing"
	else
		git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
	fi
}
