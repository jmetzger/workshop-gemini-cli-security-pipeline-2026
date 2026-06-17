# Installation 

## Prerquisites 

  * Docker muss laufen

## Gemini CLI instalieren und starten 

```
# Grundeinstellungen vornehmen, so dass er nicht mehr nachfragt

mkdir -p ~/.gemini
cat > ~/.gemini/settings.json << 'EOF'
{
  "ui": {
    "theme": "Default Light"
  },
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  }
}
EOF
```


```
echo 'export COLORTERM=truecolor' >> ~/.bashrc
source ~/.bashrc
npm install -g @google/gemini-cli
```

```
echo "export GEMINI_API_KEY=DEINAPIKEY" >> ~/.env
```

```
source ~/.env
mkdir -p testproject
cd testproject
gemini --sandbox
# oder 
# gemini --skip-trust --sandbox
```

```
# in gemini-cli
# Wird sandbox verwendet ? 
/about
```

## /about ohne Sandbox 

<img width="1877" height="425" alt="image" src="https://github.com/user-attachments/assets/41c3bac1-c394-4751-add3-fd0cbb41cbbd" />

