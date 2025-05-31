#!/bin/bash
# Script unificado para criar projeto React Router com shadcn/ui e Dark Mode
# Uso: ./setup-project.sh nome-do-projeto

# --- Configuração ---
PROJECT_NAME=$1
BASE_COLOR="stone"
DIR_ATUAL=$(pwd)
PATH_COMPLETO=$DIR_ATUAL/$PROJECT_NAME

# Verificar se o nome do projeto foi fornecido
if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Erro: Nome do projeto é obrigatório"
  echo "Uso: ./setup-project.sh nome-do-projeto"
  exit 1
fi

# --- Funções Auxiliares ---
print_message() {
  echo "-----------------------------------------------------"
  echo "$1"
  echo "-----------------------------------------------------"
}

print_step() {
  echo ""
  echo "🔄 $1"
}

print_success() {
  echo "✅ $1"
}

print_error() {
  echo "❌ $1"
  exit 1
}

# --- PARTE 1: CRIAÇÃO DO PROJETO ---
print_message "🚀 Criando projeto React Router com shadcn/ui e Dark Mode"
print_message "Projeto: $PROJECT_NAME"
print_message "Diretório: $PATH_COMPLETO"

# 1. Criar e entrar no diretório do projeto
print_step "Criando diretório do projeto..."
mkdir "$PROJECT_NAME" || print_error "Falha ao criar diretório"
cd "$PROJECT_NAME" || print_error "Falha ao entrar no diretório"
print_success "Diretório criado"

# 2. Criar projeto React Router
print_step "Criando projeto React Router..."
pnpm dlx create-react-router@latest . -y || print_error "Falha ao criar projeto React Router"

if [ ! -f "package.json" ]; then
  print_error "Projeto React Router não foi criado corretamente"
fi
print_success "Projeto React Router criado"

# 3. Inicializar shadcn/ui
print_step "Inicializando shadcn/ui..."
pnpm dlx shadcn@latest init -b "$BASE_COLOR" -y -f --no-src-dir || print_error "Falha ao inicializar shadcn/ui"

if [ ! -f "components.json" ]; then
  print_error "shadcn/ui não foi inicializado corretamente"
fi
print_success "shadcn/ui inicializado"

# 4. Adicionar componentes shadcn/ui
print_step "Adicionando componentes shadcn/ui..."
pnpm dlx shadcn@latest add --all -o || print_error "Falha ao adicionar componentes"
print_success "Componentes shadcn/ui adicionados"

# --- PARTE 2: CONFIGURAÇÃO DO DARK MODE ---
print_message "🌙 Configurando Dark Mode..."

# 5. Limpar ambiente e parar servidores
print_step "Limpando ambiente..."
pkill -f "react-router dev" 2>/dev/null || true
rm -rf .react-router build 2>/dev/null || true
print_success "Ambiente limpo"

# 6. Instalar remix-themes
print_step "Instalando dependências para dark mode..."
pnpm add remix-themes || print_error "Falha ao instalar remix-themes"
print_success "Dependências instaladas"

# 7. Atualizar app.css
print_step "Configurando app.css..."
if ! grep -q ":root\[class~=\"dark\"\]" app/app.css; then
  cat >> app/app.css << 'EOF'

.dark,
:root[class~="dark"] {
  color-scheme: dark;
}
EOF
fi
print_success "app.css configurado"

# 8. Criar SimpleThemeProvider
print_step "Criando SimpleThemeProvider..."
cat > app/components/simple-theme-provider.tsx << 'EOF'
import React, { createContext, useContext, useEffect, useState } from "react";

type Theme = "dark" | "light" | "system";

interface ThemeProviderProps {
  children: React.ReactNode;
  defaultTheme?: Theme;
}

interface ThemeProviderState {
  theme: Theme;
  setTheme: (theme: Theme) => void;
}

const initialState: ThemeProviderState = {
  theme: "system",
  setTheme: () => null,
};

const ThemeProviderContext = createContext<ThemeProviderState>(initialState);

export function SimpleThemeProvider({
  children,
  defaultTheme = "system",
}: ThemeProviderProps) {
  const [theme, setTheme] = useState<Theme>(defaultTheme);

  useEffect(() => {
    const storedTheme = localStorage.getItem("theme") as Theme;
    if (storedTheme) {
      setTheme(storedTheme);
    }
  }, []);

  useEffect(() => {
    const root = window.document.documentElement;
    root.classList.remove("light", "dark");

    if (theme === "system") {
      const systemTheme = window.matchMedia("(prefers-color-scheme: dark)")
        .matches ? "dark" : "light";
      root.classList.add(systemTheme);
      return;
    }

    root.classList.add(theme);
  }, [theme]);

  const value = {
    theme,
    setTheme: (theme: Theme) => {
      localStorage.setItem("theme", theme);
      setTheme(theme);
    },
  };

  return (
    <ThemeProviderContext.Provider value={value}>
      {children}
    </ThemeProviderContext.Provider>
  );
}

export const useTheme = () => {
  const context = useContext(ThemeProviderContext);

  if (context === undefined) {
    throw new Error("useTheme must be used within a ThemeProvider");
  }

  return context;
};
EOF
print_success "SimpleThemeProvider criado"

# 9. Criar SimpleModeToggle
print_step "Criando SimpleModeToggle..."
cat > app/components/simple-mode-toggle.tsx << 'EOF'
import { Moon, Sun } from "lucide-react";
import { Button } from "./ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "./ui/dropdown-menu";
import { useTheme } from "./simple-theme-provider";

export function SimpleModeToggle() {
  const { setTheme } = useTheme();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <Sun className="h-[1.2rem] w-[1.2rem] scale-100 rotate-0 transition-all dark:scale-0 dark:-rotate-90" />
          <Moon className="absolute h-[1.2rem] w-[1.2rem] scale-0 rotate-90 transition-all dark:scale-100 dark:rotate-0" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")}>Light</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")}>Dark</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")}>System</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
EOF
print_success "SimpleModeToggle criado"

# 10. Atualizar welcome.tsx
print_step "Atualizando welcome.tsx com dark mode..."
cat > app/welcome/welcome.tsx << 'EOF'
import { SimpleThemeProvider } from "~/components/simple-theme-provider";
import { SimpleModeToggle } from "~/components/simple-mode-toggle";
import { Button } from "~/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "~/components/ui/card";
import logoDark from "./logo-dark.svg";
import logoLight from "./logo-light.svg";

export function Welcome() {
  return (
    <SimpleThemeProvider defaultTheme="system">
      <div className="min-h-screen bg-background text-foreground">
        <header className="border-b">
          <div className="container mx-auto px-4 py-4 flex justify-between items-center">
            <div className="flex items-center gap-4">
              <div className="w-[120px]">
                <img
                  src={logoLight}
                  alt="React Router"
                  className="block w-full dark:hidden"
                />
                <img
                  src={logoDark}
                  alt="React Router"
                  className="hidden w-full dark:block"
                />
              </div>
              <h1 className="text-2xl font-bold">Task Master</h1>
            </div>
            <SimpleModeToggle />
          </div>
        </header>
        
        <main className="container mx-auto px-4 py-8">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle>🌙 Dark Mode Configurado!</CardTitle>
                <CardDescription>
                  Sistema de temas completo e funcional
                </CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground mb-4">
                  Use o botão no canto superior direito para alternar entre temas claro, escuro e automático.
                </p>
                <Button>Testar Componente</Button>
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader>
                <CardTitle>✨ Features Implementadas</CardTitle>
                <CardDescription>
                  O que foi configurado
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="text-sm space-y-2">
                  <li>✅ Theme Provider simplificado</li>
                  <li>✅ LocalStorage para persistência</li>
                  <li>✅ Toggle component funcional</li>
                  <li>✅ Suporte ao tema do sistema</li>
                  <li>✅ Transições suaves</li>
                  <li>✅ Sem dependência de cookies</li>
                </ul>
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader>
                <CardTitle>🚀 Como usar</CardTitle>
                <CardDescription>
                  Implementação em outros componentes
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="text-sm space-y-2">
                  <li>• Importe `SimpleThemeProvider`</li>
                  <li>• Use `SimpleModeToggle` onde necessário</li>
                  <li>• Classes `dark:` funcionam automaticamente</li>
                  <li>• Tema é salvo no localStorage</li>
                  <li>• Funciona offline</li>
                </ul>
              </CardContent>
            </Card>
            
            <Card className="md:col-span-2 lg:col-span-3">
              <CardHeader>
                <CardTitle>📚 Próximos Passos</CardTitle>
                <CardDescription>
                  Como expandir o dark mode para toda a aplicação
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid md:grid-cols-2 gap-4">
                  <div>
                    <h4 className="font-medium mb-2">Para usar globalmente:</h4>
                    <ul className="text-sm space-y-1">
                      <li>1. Adicione `SimpleThemeProvider` no root.tsx</li>
                      <li>2. Substitua qualquer outro theme provider</li>
                      <li>3. Use `SimpleModeToggle` em layouts</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="font-medium mb-2">Classes Tailwind úteis:</h4>
                    <ul className="text-sm space-y-1">
                      <li>• `dark:bg-gray-900` para fundos escuros</li>
                      <li>• `dark:text-white` para texto claro</li>
                      <li>• `dark:border-gray-700` para bordas</li>
                    </ul>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </main>
      </div>
    </SimpleThemeProvider>
  );
}
EOF
print_success "welcome.tsx atualizado"

# 11. Atualizar root.tsx
print_step "Configurando root.tsx..."
cat > app/root.tsx << 'EOF'
import {
  isRouteErrorResponse,
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "react-router";

import type { Route } from "./+types/root";
import "./app.css";
import { SimpleThemeProvider } from "./components/simple-theme-provider";

export const links: Route.LinksFunction = () => [
  { rel: "preconnect", href: "https://fonts.googleapis.com" },
  {
    rel: "preconnect",
    href: "https://fonts.gstatic.com",
    crossOrigin: "anonymous",
  },
  {
    rel: "stylesheet",
    href: "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap",
  },
];

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <SimpleThemeProvider defaultTheme="system">
          {children}
        </SimpleThemeProvider>
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

export default function App() {
  return <Outlet />;
}

export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  let message = "Oops!";
  let details = "An unexpected error occurred.";
  let stack: string | undefined;

  if (isRouteErrorResponse(error)) {
    message = error.status === 404 ? "404" : "Error";
    details =
      error.status === 404
        ? "The requested page could not be found."
        : error.statusText || details;
  } else if (import.meta.env.DEV && error && error instanceof Error) {
    details = error.message;
    stack = error.stack;
  }

  return (
    <main className="pt-16 p-4 container mx-auto">
      <h1>{message}</h1>
      <p>{details}</p>
      {stack && (
        <pre className="w-full p-4 overflow-x-auto">
          <code>{stack}</code>
        </pre>
      )}
    </main>
  );
}
EOF
print_success "root.tsx configurado"

# 12. Reinstalar dependências
print_step "Finalizando instalação..."
pnpm install || print_error "Falha ao instalar dependências finais"
print_success "Instalação finalizada"

# --- FINALIZAÇÃO ---
cd "$PATH_COMPLETO"

pnpm dlx shadcn@latest add https://tweakcn.com/r/themes/claude.json

print_message "🎉 PROJETO CRIADO COM SUCESSO!"
echo ""
echo "📦 Projeto: $PROJECT_NAME"
echo "📍 Localização: $PATH_COMPLETO"
echo ""
echo "✨ O que foi configurado:"
echo "  • ⚛️  React Router com TypeScript"
echo "  • 🎨 shadcn/ui com todos os componentes"
echo "  • 🌙 Dark Mode completo e funcional"
echo "  • 💾 Persistência no localStorage"
echo "  • 🎯 Theme Provider simplificado"
echo "  • 🔄 Toggle de tema automático"
echo ""
echo "🚀 Para iniciar o projeto:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
echo ""
echo "🌐 Acesse: http://localhost:5173"
echo ""
echo "🎯 Use o botão de tema no canto superior direito!"
echo ""
print_message "✅ Setup completo finalizado com sucesso!"