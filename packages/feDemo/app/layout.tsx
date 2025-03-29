import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"
import Navbar from "@/components/navbar"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Weth++ | Enhanced Yield-Bearing Tokens",
  description: "Interact with PlusPlus tokens, enhanced yield-bearing versions of existing tokens",
    generator: 'v0.dev'
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-black text-gray-300 min-h-screen`}>
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem={false}>
          <div className="flex flex-col min-h-screen">
            <Navbar />
            <main className="flex-1 container mx-auto px-4 py-8">{children}</main>
            <footer className="border-t border-gray-800 py-6 px-4">
              <div className="container mx-auto">
                <div className="flex justify-between items-center">
                  <div className="text-sm text-gray-500">© 2023 Weth++. All rights reserved.</div>
                  <div className="flex space-x-4">
                    <a href="#" className="text-gray-500 hover:text-gray-300">
                      Terms
                    </a>
                    <a href="#" className="text-gray-500 hover:text-gray-300">
                      Privacy
                    </a>
                    <a href="#" className="text-gray-500 hover:text-gray-300">
                      Docs
                    </a>
                  </div>
                </div>
              </div>
            </footer>
          </div>
        </ThemeProvider>
      </body>
    </html>
  )
}



import './globals.css'