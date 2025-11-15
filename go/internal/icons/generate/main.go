package main

//go:generate go run .

import (
	"log"

	"github.com/patrickward/go-heroicons"
)

func main() {
	generator := &heroicons.Generator{
		HeroiconsPath: "/tmp/heroicons",
		OutputPath:    "../",
		PackageName:   "icons",
		Icons: []heroicons.IconSet{
			// Outline icons (24px)
			{Name: "bars-3", Type: heroicons.IconOutline},
			{Name: "cog-6-tooth", Type: heroicons.IconOutline},
			{Name: "user-circle", Type: heroicons.IconOutline},
			// Mini icons (20px solid)
			{Name: "check", Type: heroicons.IconMini},
			{Name: "plus", Type: heroicons.IconMini},
			{Name: "lock-closed", Type: heroicons.IconMini},
			{Name: "arrow-left-start-on-rectangle", Type: heroicons.IconMini},
		},
		FailOnError: true,
	}

	if err := generator.Generate(); err != nil {
		log.Fatal(err)
	}

	log.Println("Icons generated successfully!")
}
