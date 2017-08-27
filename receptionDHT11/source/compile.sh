#/bin/bash
echo "Compilation"
g++ reception.c -o recepteurDHT11 -lwiringPi
echo "Copie du résultat"
chmod +x recepteurDHT11
cp recepteurDHT11 ../recepteurDHT11
./recepteurDHT11