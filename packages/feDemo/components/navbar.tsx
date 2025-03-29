"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { Menu, X, Wallet, ChevronDown, LogOut, Copy, ExternalLink } from "lucide-react"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const pathname = usePathname()

  // Connected wallet address
  const walletAddress = "0xBc3bb6a87309004C11ADdd584545Bc8daf5e8CD7"

  // Function to shorten address for display
  const shortenAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  // Function to copy address to clipboard
  const copyAddressToClipboard = () => {
    navigator.clipboard.writeText(walletAddress)
  }

  // Function to open etherscan in a new tab
  const openEtherscan = () => {
    window.open(`https://etherscan.io/address/${walletAddress}`, "_blank")
  }

  const navItems = [
    { name: "Pools", href: "/" },
    { name: "Tokens", href: "/tokens" },
    { name: "Positions", href: "/positions" },
  ]

  return (
    <nav className="border-b border-gray-800 bg-black/90 backdrop-blur-sm sticky top-0 z-50">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center">
            <Link href="/" className="flex items-center">
              <img src="/images/weth-plus-plus.svg" alt="Weth++ Logo" className="h-6 w-6 mr-2" />
              <span className="text-xl font-bold bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent">
                Weth++
              </span>
            </Link>
          </div>

          <div className="hidden md:flex items-center space-x-8">
            <div className="flex space-x-6">
              {navItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    "text-sm font-medium transition-colors hover:text-white",
                    pathname === item.href ? "text-white" : "text-gray-500",
                  )}
                >
                  {item.name}
                </Link>
              ))}
            </div>

            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="outline"
                  className="border-gray-700 hover:bg-gray-800 hover:text-white text-gray-300 flex items-center gap-2"
                >
                  <div className="w-2 h-2 rounded-full bg-green-500"></div>
                  <Wallet size={16} />
                  {shortenAddress(walletAddress)}
                  <ChevronDown size={14} />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent className="w-56 bg-gray-900 border-gray-800">
                <div className="px-2 py-1.5 text-sm text-gray-400">Connected Wallet</div>
                <DropdownMenuSeparator className="bg-gray-800" />
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <DropdownMenuItem
                        className="flex cursor-pointer items-center text-gray-300 focus:text-white focus:bg-gray-800"
                        onClick={copyAddressToClipboard}
                      >
                        <Copy size={14} className="mr-2" />
                        {shortenAddress(walletAddress)}
                      </DropdownMenuItem>
                    </TooltipTrigger>
                    <TooltipContent>
                      <p className="text-xs">Copy address to clipboard</p>
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
                <DropdownMenuItem
                  className="flex cursor-pointer items-center text-gray-300 focus:text-white focus:bg-gray-800"
                  onClick={openEtherscan}
                >
                  <ExternalLink size={14} className="mr-2" />
                  View on Etherscan
                </DropdownMenuItem>
                <DropdownMenuSeparator className="bg-gray-800" />
                <DropdownMenuItem className="flex cursor-pointer items-center text-red-400 focus:text-red-300 focus:bg-gray-800">
                  <LogOut size={14} className="mr-2" />
                  Disconnect
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <div className="md:hidden flex items-center">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-gray-400 hover:text-white focus:outline-none"
            >
              {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      {isMenuOpen && (
        <div className="md:hidden bg-gray-900/95 backdrop-blur-sm">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "block px-3 py-2 rounded-md text-base font-medium",
                  pathname === item.href
                    ? "bg-gray-800 text-white"
                    : "text-gray-400 hover:bg-gray-800 hover:text-white",
                )}
                onClick={() => setIsMenuOpen(false)}
              >
                {item.name}
              </Link>
            ))}
            <div className="pt-4 pb-2">
              <Button
                variant="outline"
                className="w-full border-gray-700 hover:bg-gray-800 hover:text-white text-gray-300 flex items-center justify-center gap-2"
              >
                <div className="w-2 h-2 rounded-full bg-green-500"></div>
                <Wallet size={16} />
                {shortenAddress(walletAddress)}
              </Button>
            </div>
          </div>
        </div>
      )}
    </nav>
  )
}

