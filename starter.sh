#!/bin/bash

############# Variables #############
serverpath=/root/servers
runServers=()

############# Functions #############
info() {
 printf "\033[0;32m[INFO]\033[0m $* \n"
}

warning() {
 printf "\033[0;31m[WARNING]\033[0m $1 \n"
}

can_exists() {
 [ -e "$1" ]
}
 
parse_screens() {
 if ! can_run screen; then
	warning "ИМПОСИБРУ!!!!! Пакет screen не установлен, это как так?!!"
	if can_run apt-get; then
		info "Пробуем установить пакет их репозитория."
		sudo apt-get install screen
	fi
 else
	screen -x | rev | cut -d . -f1 -s | rev | cut -d " " -f 1 -s | awk -F" " '{print $1}'
 fi
}

clear_newLine() {
 "$@" | sed ':a;N;$!ba;s/\n/ /g'
}

clear_whitespaces(){
 "$@" | tr -d " \t\n\r" 
}

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

prepareToRun () {
 runServers+=("$1")
 info "$1 не найден в списке запущенных, и поставлен в очередь на запуск"
}

can_run() {
 (test -x "$1" || which "$1") &>/dev/null
}

createScreen() {
 screen -dmS "$1" "$2"
}

findServerPath() {
 echo $serverpath/$1/start.sh
 info "Команда запуска отправлена на скрин"
}

startCommand() {
 screen -S $1 -p 0 -X stuff "sh $2`echo -ne '\015'`"
}

############# Core #############

if can_exists servers.txt; then
	info "Файл со списком серверов был найден. Пробуем собрать массив c серверами."
else
	warning "Файл со списком серверов не был найден. Создайте в папке со скриптом файл servers.txt и впишите названия серверов, начиная каждое с новой строки"
	exit 1;
fi

if readarray servers < servers.txt; then
	info "Массив с серверами успешно собран. Количество элементов - ${#servers[@]}"
else
	warning "Массив собрать не удалось."
	exit 1;
fi

if readarray screens < <(parse_screens); then
	info "Массив со скринами успешно собран. Количество элементов - ${#screens[@]}"
else
	warning "Массив собрать не удалось."
	exit 1;
fi

total=${#servers[*]}
for (( i=0; i<=$(( $total -1 )); i++ ))
do
	if ! containsElement "${servers[$i]}" "${screens[@]}"; then
		server=${servers[$i]}
		prepareToRun $server
	fi
done

total=${#runServers[*]}
for (( i=0; i<=$(( $total -1 )); i++ ))
do
 server=${runServers[$i]}
 path="$(findServerPath $server)"
 createScreen $server
 startCommand $server $path
done
