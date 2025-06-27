package logger

import (
	"fmt"
	"go.uber.org/zap"
)

func Debug(msg string, v ...any) {
	zap.L().Debug(fmt.Sprintf(msg, v...))
}

func Info(msg string, v ...any) {
	zap.L().Info(fmt.Sprintf(msg, v...))
}

func Warn(msg string, v ...any) {
	zap.L().Warn(fmt.Sprintf(msg, v...))
}

func Error(msg string, v ...any) {
	zap.L().Error(fmt.Sprintf(msg, v...))
}
