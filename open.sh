#!/bin/bash

if [[ "$@" =~ "https://" ]] || [[ "$@" =~ "http://" ]]; then
	echo "[Info] Received a request: $@, interpreting as link"
	/usr/lib/flatpak-xdg-utils/xdg-open "$@"
	exit $?
fi

if [[ $1 =~ "/" ]]; then
	export origReq="$1"
fi

if [[ $2 =~ "/" ]]; then
	export origReq="$2"
fi

if [ ${trashAppUnsafe} ]; then
	link="${origReq}"
	xdg-open "${origReq}"
	exit $?
fi

if [[ $(echo ${origReq} | cut -c '1-8') =~ 'file://'  ]]; then
	echo "Received a request with file://: ${origReq}"
	export origReq="$(echo ${origReq} | sed 's|file:///|/|g')"
	echo "Decoding path as: ${origReq}"
else
	export origReq="$(realpath ${origReq})"
fi

export bwBindPar="$(realpath ${bwBindPar})"

if [[ "${origReq}" =~ "${bwBindPar}" ]] && [ ! -z ${bwBindPar} ]; then
	echo "[Warn] Request is in bwBindPar!"
	export link="/proc/$(cat ~/mainPid)/root${origReq}"
else
	ln \
		-sfr \
		${origReq} ~/Shared
	link="${XDG_DATA_HOME}/${stateDirectory}/Shared/$(basename ${origReq})"
fi

echo "[Info] received a request: $@, translated to ${link}"

# if [[ ${portableUsePortal} = 1 ]]; then
# 	/usr/lib/flatpak-xdg-utils/xdg-open $(dirname "${link}")
# 	if [[ $? = 0 ]]; then
# 		exit 0
# 	fi
# fi
echo "[Info] Initiating D-Bus call..."
dbus-send --print-reply --dest=org.freedesktop.FileManager1 \
	/org/freedesktop/FileManager1 \
	org.freedesktop.FileManager1.ShowItems \
	array:string:"file://${link}" \
	string:fake-dde-show-items

if [[ $? = 0 ]]; then
	exit 0
fi

/usr/lib/flatpak-xdg-utils/xdg-open $(dirname "${link}")

if [[ $? = 0 ]]; then
	exit 0
fi


if [ -f /usr/bin/dolphin ] && [ ${XDG_CURRENT_DESKTOP} = KDE ]; then
	/usr/bin/dolphin --select "${link}"
elif [ -f /usr/bin/nautilus ] && [ ${XDG_CURRENT_DESKTOP} = GNOME ]; then
	/usr/bin/nautilus $(dirname "${link}")
else
	xdg-open $(dirname "${link}")
fi
fi
