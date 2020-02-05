#!/bin/bash
######################
TR_TORRENT_DIR=${TR_TORRENT_DIR:-$1}
TR_TORRENT_NAME=${TR_TORRENT_NAME:-$2}
torrentPath=${TR_TORRENT_DIR}/${TR_TORRENT_NAME}
log_prefix="Transmission-Daemon"
_log() {
  logger -t ${log_prefix} "$@"
}
_find_rars () {
  find "${1}" -type -f \( -iname \*.rar  -o -iname \*.part1.rar -o -iname \*.part01.rar \)
}
_unrar_torrent () {
  find "${1}" \( -iname \*.rar -o -iname \*.part1.rar -o -iname \*.part01.rar \)  -execdir unrar e {} "${2}" ";"
}
_log "$TR_TORRENT_NAME is finished, processing directory for unpacking"
if [ -f "${torrentPath}" ];then
  _log "Single file torrent, nothing to do"
  exit
elif [ -n $( _find_rars "${torrentPath}" ) ];then
  _log "Torrent with rar files, unpacking"
  _unrar_torrent ${torrentPath} .
else
  _log "No rar files found"
fi