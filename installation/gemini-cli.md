# Installation 

## Prerquisites 

  * Docker muss laufen

## Gemini CLI instalieren und starten 

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
mkdir testproject
cd testproject
gemini --sandbox
# oder 
gemini --skip-trust --sandbox
```

```
# in gemini-cli
/about
```

