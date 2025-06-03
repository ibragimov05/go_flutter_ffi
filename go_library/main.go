package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

//export HelloWorld
func HelloWorld() *C.char {
	message := "Hello, world from Go!"

	return C.CString(message)
}

//export FreeString
func FreeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

//export AddNumbers
func AddNumbers(a, b C.int) C.int {
	return a + b
}

func main() {}
