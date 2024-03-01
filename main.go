package main

import (
	"io"
	"net/http"
)

func hello(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "[v2] Hello, Kubernetes!\n")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe(":3000", nil)
}

//func main() {
//	wg := sync.WaitGroup{}
//	for i := 0; i < 5; i++ {
//		wg.Add(1)
//		go func(wg *sync.WaitGroup, i int) {
//			fmt.Printf("i:%d", i)
//			wg.Done()
//		}(&wg, i)
//	}
//	wg.Wait()
//	fmt.Println("exit")
//}
