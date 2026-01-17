


```bash
docker run --name my-abb --rm -it -v /"$PWD:/app" -w //app beevelop/android:v2025.08.1 bash
```


```bash
apt-get update
apt-get install -y curl ca-certificates

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

node -v
npm -v

yes | /opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android --licenses
/opt/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android "ndk;27.1.12297006"
```




```bash
npx @react-native-community/cli init MyApp --version 0.83.0
cd MyApp/android
./gradlew assembleRelease

```





