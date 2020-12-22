#This test script aims to stress middleware and launcher.

Bla='\e[0;30m'; On_Red='\e[41m'; On_Gre='\e[42m'; BYel='\e[1;33m'; Cya='\e[0;36m'; BIBlu='\e[1;94m'; Gre='\e[0;32m'; Red='\e[0;31m'; Pur='\e[0;35m'; # Text colors
RCol='\e[0m' # Text Reset

#Completes profiles screen by selecting main profile and input default PIN (0000).
run_profiles() {
  Profiles=$(dumpsys window windows | grep -E mCurrentFocus)
  if [[ $Profiles == *"ProfileManagementActivity"* ]]; then
    sleep 1
    input keyevent KEYCODE_BACK      #Closes PIN menu if opened
    input keyevent KEYCODE_DPAD_DOWN #LOCATES SELECTION TO MAIN PROFILE
    input keyevent KEYCODE_DPAD_CENTER
    sleep 1
    input text "0000"
  fi
  return
}

# Version of script running.
echo "$BYel"".------------------------------------------------.
|     Running Channel Change Test Script v1.4    |
|   _____ _______ ____     _____ _      __ ___   |
|  / ____|__   __|  _ \   |  __ \ \    / /  _ \  |
| | (___    | |  | |_) |__| |  | \ \  / /| |_) | |
|  \___ \   | |  |  _ <|__| |  | |\ \/ / |  _ <  |
|  ____) |  | |  | |_) |  | |__| | \  /  | |_) | |
| |_____/   |_|  |____/   |_____/   \/   |____/  |
|                                                |
'------------------------------------------------'"$RCol
echo

sleep 5
run_profiles

#Reads device under test information
Model=$(getprop ro.product.vendor.device)
Snum=$(getprop ro.serialno)
MacA=$(getprop ro.boot.mac)
Aver=$(getprop ro.build.version.release)
Build=$(getprop ro.product.version.base)
Launcher=$(dumpsys package com.dotscreen.megacable.livetv | grep versionName | cut -d "=" -f2)
IPv4=$(ip route | cut -d " " -f9)
Apro=$(logcat -d | grep modelExternalId | cut -d " " -f 11)
timestamp1=$(date "+%Y%m%d%H%M%S") #Update timestamp for logs name.
crashLog1=0; LiveTVcrashCount=0; DtvCrashCount=0; MulticastCrashCount=0; PortalCrashCount=0; TotalCrashCount=0; varCount=0; testCount=0
TestN=0; vCount=0; aCount=0; ChannelN=0; LoadCPU=0; FreeRAM=0; AvgCPU=0; SumCPU=0; AvgRAM=0; SumRAM=0; MBF=0; AvgMBF0=0; AvgMBF=0; SumMBF=0
cd sdcard/Automation
mkdir Crashes

echo 'Test Results' > TestResults
echo 'Inestability Events' > InestabilityEvents

sleep .5
#Prints device under test information.
echo
echo "$BYel""----------DEVICE INFO----------""$RCol"
echo "$BIBlu""Model:""$RCol" "$Model" "-" "${Apro:0:5}"
echo "$BIBlu""Serial Number:""$RCol" "$Snum"
echo "Serial Number","$Snum" >> TestResults
echo "$BIBlu""MAC Address:""$RCol" "$MacA"
echo "MAC Address","$MacA" >> TestResults
echo "$BIBlu""IP Address:""$RCol" "$IPv4"
echo "$BIBlu""Android:""$RCol" "$Aver"
echo "$BIBlu""Build:""$RCol" "${Build:0:6}"
echo "Build","${Build:0:6}" >> TestResults
echo "$BIBlu""Launcher:""$RCol" "${Launcher:0:6}"
echo "Launcher","${Launcher:0:6}" >> TestResults
echo

echo "Timestamp,TEST #,Channel Up,Channel Down,Move Right,Move Left,Channel,Crashes,CPU Load,Free RAM (MB),MBF,Audio,Video" >> TestResults
echo "Tests Executed,Video Fails,Audio Fails,LiveTV Crashes,Portal Crashes,Dtv Crashes,Multicast Crashes,Total Crashes,Avg CPU Load,Avg Free RAM (MB),Avg MBF(Sec)" >> InestabilityEvents

#scan process:
logcat -c
echo ${BIBlu}"Performing a channel scan..."
sleep 2
input keyevent KEYCODE_HOME
sleep 2
for i in $(seq 7); do
  input keyevent KEYCODE_DPAD_DOWN
done
for i in $(seq 4); do
  input keyevent KEYCODE_DPAD_LEFT
done
input keyevent KEYCODE_DPAD_CENTER
for i in $(seq 4); do
  input keyevent KEYCODE_DPAD_RIGHT
done
input keyevent KEYCODE_DPAD_DOWN
input keyevent KEYCODE_DPAD_CENTER

SResult=0
sleep 15

#For scan success
Scan=$(logcat -d | grep SCAN_STATUS_TIF_UPDATE_DONE)
if [[ $Scan == *"SCAN_STATUS_OK"* ]]; then
  SResult=$Gre"Complete!"$RCol
  echo "Scan process" "$SResult", "$BIBlu""Channels found:""${RCol}""$Gre""${Scan:(-3)}""$RCol"
fi

Scan1=$(logcat -d | grep SCAN_STATUS_ERROR)
#For scan fail
if [[ $Scan1 == *"No channel found"* ]]; then
  SResult=${Bla}${On_Red}"FAIL"${RCol}${BIBlu}" Channels found:"${RCol}"0"
  echo "${BIBlu}""Scan process" "$SResult"
  echo $Red"Reboot STB and restart test script."$Rcol
  sleep 3
  reboot
fi

Scan2=$(logcat -d | grep SCAN_STATUS_ERROR)
#For scan fail
if [[ $Scan2 == *"null"* ]]; then
  SResult=${Bla}${On_Red}"FAIL"${RCol}${BIBlu}" Channels found:"${RCol}"0"
  echo "${BIBlu}""Scan process" "$SResult"
  echo $Red"Please verify DVB-C connection!... Otherwise, reboot STB and restart test script."$Rcol
  sleep 3
  reboot
fi

echo "${BIBlu}""Test set up in progress...""${RCol}"
sleep 10
run_profiles
sleep 2

#Here, script will start with the automatic set up, go to home and tune 100 channel.
input keyevent KEYCODE_HOME
sleep 2
input keyevent KEYCODE_HOME
input text "1212"
sleep .5
input keyevent KEYCODE_DPAD_CENTER
sleep 5
Channel=$(logcat -d | grep displayNumber | grep onZap | cut -d "," -f5 | cut -b16-19) #Update current channel.
ChannelN=$(printf "%04d" "${Channel:(-4)}")

echo $BYel"-----------------------------------------------Test begins here!-------------------------------------------------"
#Read PID from net.oregan.tvinput.dtv middleware
StartDtvPID=$(pidof net.oregan.tvinput.dtv)
CurrtDtvPID=$(pidof net.oregan.tvinput.dtv)

#Read PID from net.oregan.tvinput.dtv middleware
StartMulticastPID=$(pidof net.oregan.tvinput.multicast)
CurrtMulticastPID=$(pidof net.oregan.tvinput.multicast)

#Read PID from live tv Launcher
StartLivetvPID=$(pidof com.dotscreen.megacable.livetv)
CurrtLivetvPID=$(pidof com.dotscreen.megacable.livetv)

#Read PID from portal Launcher
StartPortalPID=$(pidof com.dotscreen.megacable.portal)
CurrtPortalPID=$(pidof com.dotscreen.megacable.portal)

call_separator(){
echo $RCol"-----------------------------------------------------------------------------------------------------------------"$RCol
return
}

#Checks whether middleware crashed.
dtv_crash() {
  CurrtDtvPID=$(pidof net.oregan.tvinput.dtv)
  if [ $StartDtvPID -eq "$CurrtDtvPID" ]; then #
    return
  else
    DtvCrashCount=$(expr $DtvCrashCount + 1) #Increase counter.
    TotalCrashCount=$(expr $TotalCrashCount + 1) #Increase counter.
    end_time="$(date -u +%s)" 
    mbf_check
    echo "$TestN,$vCount,$aCount,$LiveTVcrashCount,$PortalCrashCount,$DtvCrashCount,$MulticastCrashCount,$TotalCrashCount,$AvgCPU"%",$AvgRAM,$AvgMBF" >> InestabilityEvents
    echo "${TimeStamp:0:19},$TestN,$RandomCHu,$RandomCHd,$RandomRight,$RandomLeft,$ChannelN,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,CRASH,CRASH" >> Testresults;
    echo "${RCol}""${TimeStamp:0:19} ---------> ${BIBlu}Channel Zapping and banner navigation test${RCol} ----------> ${Cya}Channel: ${RCol}${ChannelN}
${Cya}TEST# $RCol$TestN, ${Cya}Ch+ ${RCol}$RandomCHu, ${Cya}Ch- ${RCol}$RandomCHd, ${Cya}Crashes ${RCol}$TotalCrashCount, ${Cya}CPU Load ${RCol}$LoadCPU, ${Cya}Free RAM ${RCol}${FreeRAM//[[:blank:]]/}, ${Cya}Curr MBF ${RCol}$CurrMBF, ${Cya}Video $Bla$On_Red"CRASH"$RCol, ${Cya}Audio $Bla$On_Red"CRASH"$RCol ";
    echo "-------------------------------------->""$Bla""$On_Red""¡MIDDLEWARE DTV CRASHED!""$RCol""<--------------------------------"
    crashLog1=$(logcat -d *:E > ./Crashes/$timestamp1-Dtv-Crash.txt)
    echo $Red"$crashLog1"$RCol
    start_time="$(date -u +%s)"
    sleep 10
    logcat -c
    sleep 5
    StartDtvPID=$(pidof net.oregan.tvinput.dtv)
    call_separator
  fi
}

multicast_crash() {
  CurrtMulticastPID=$(pidof net.oregan.tvinput.multicast)
  if [ $StartMulticastPID -eq "$CurrtMulticastPID" ]; then #
    return
  else
    MulticastCrashCount=$(expr $MulticastCrashCount + 1) #Increase counter.
    TotalCrashCount=$(expr $TotalCrashCount + 1) #Increase counter.
    end_time="$(date -u +%s)"
    mbf_check
    echo "$TestN,$vCount,$aCount,$LiveTVcrashCount,$PortalCrashCount,$DtvCrashCount,$MulticastCrashCount,$TotalCrashCount,$AvgCPU"%",$AvgRAM,$AvgMBF" >> InestabilityEvents
    echo "${TimeStamp:0:19},$TestN,$RandomCHu,$RandomCHd,$RandomRight,$RandomLeft,$ChannelN,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,CRASH,CRASH" >> Testresults;
    echo "${RCol}""${TimeStamp:0:19} ---------> ${BIBlu}Channel Zapping and banner navigation test${RCol} ----------> ${Cya}Channel: ${RCol}${ChannelN}
${Cya}TEST# $RCol$TestN, ${Cya}Ch+ ${RCol}$RandomCHu, ${Cya}Ch- ${RCol}$RandomCHd, ${Cya}Crashes ${RCol}$TotalCrashCount, ${Cya}CPU Load ${RCol}$LoadCPU, ${Cya}Free RAM ${RCol}${FreeRAM//[[:blank:]]/}, ${Cya}Curr MBF ${RCol}$CurrMBF, ${Cya}Video $Bla$On_Red"CRASH"$RCol, ${Cya}Audio $Bla$On_Red"CRASH"$RCol ";
    echo "-------------------------------------->""$Bla""$On_Red""¡MIDDLEWARE TV INPUT CRASHED!""$RCol""<----------------------------"
    crashLog1=$(logcat -d *:E > ./Crashes/$timestamp1-Multicast-Crash.txt)
    echo $Red"$crashLog1"$RCol
    start_time="$(date -u +%s)"
    sleep 10
    logcat -c
    sleep 5
    StartMulticastPID=$(pidof net.oregan.tvinput.multicast)
    call_separator
  fi
}

#Checks whether live tv end crashed.
livetv_crash() {
  CurrtLivetvPID=$(pidof com.dotscreen.megacable.livetv)
  if [ "$StartLivetvPID" -eq "$CurrtLivetvPID" ]; then 
    return
  else
    LiveTVcrashCount=$(expr $LiveTVcrashCount + 1) #Increase counter.
    TotalCrashCount=$(expr $TotalCrashCount + 1) #Increase counter.
    mbf_check
    echo "$TestN,$vCount,$aCount,$LiveTVcrashCount,$PortalCrashCount,$DtvCrashCount,$MulticastCrashCount,$TotalCrashCount,$AvgCPU"%",$AvgRAM,$AvgMBF" >> InestabilityEvents
    echo "${TimeStamp:0:19},$TestN,$RandomCHu,$RandomCHd,$RandomRight,$RandomLeft,$ChannelN,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,CRASH,CRASH" >> Testresults;
    echo "${RCol}""${TimeStamp:0:19} ---------> ${BIBlu}Channel Zapping and banner navigation test${RCol} ----------> ${Cya}Channel: ${RCol}${ChannelN}
${Cya}TEST# $RCol$TestN, ${Cya}Ch+ ${RCol}$RandomCHu, ${Cya}Ch- ${RCol}$RandomCHd, ${Cya}Crashes ${RCol}$TotalCrashCount, ${Cya}CPU Load ${RCol}$LoadCPU, ${Cya}Free RAM ${RCol}${FreeRAM//[[:blank:]]/}, ${Cya}Curr MBF ${RCol}$CurrMBF, ${Cya}Video $Bla$On_Red"CRASH"$RCol, ${Cya}Audio $Bla$On_Red"CRASH"$RCol ";
    echo "-------------------------------------->""$Bla""$On_Red""¡LAUNCHER LIVE TV CRASHED!""$RCol""<-------------------------------"
    crashLog1=$(logcat -d *:E > ./Crashes/$timestamp1-LiveTV-Crash.txt)
    echo $Red"$crashLog1"$RCol
    start_time="$(date -u +%s)"
    curr_time=0
    sleep 10
    logcat -c
    sleep 5
    echo "$RCol""Re-starting Live TV"
    am start -n com.dotscreen.megacable.livetv/com.dotscreen.tv.MainActivity
    sleep 1
    StartLivetvPID=$(pidof com.dotscreen.megacable.livetv)
    call_separator
  fi
  return
}

#Checks whether portal crashed
portal_crash() {
    CurrtPortalPID=$(pidof com.dotscreen.megacable.portal)
  if [ "$StartPortalPID" -eq "$CurrtPortalPID" ]; then 
    return
  else
    PortalCrashCount=$(expr $PortalCrashCount + 1) #Increase counter.
    TotalCrashCount=$(expr $TotalCrashCount + 1) #Increase counter.
    mbf_check
    echo "$TestN,$vCount,$aCount,$LiveTVcrashCount,$PortalCrashCount,$DtvCrashCount,$MulticastCrashCount,$TotalCrashCount,$AvgCPU"%",$AvgRAM,$AvgMBF" >> InestabilityEvents
    echo "${TimeStamp:0:19},$TestN,$RandomCHu,$RandomCHd,$RandomRight,$RandomLeft,$ChannelN,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,CRASH,CRASH" >> Testresults;
    echo "${RCol}""${TimeStamp:0:19} ---------> ${BIBlu}Channel Zapping and banner navigation test${RCol} ----------> ${Cya}Channel: ${RCol}${ChannelN}
${Cya}TEST# $RCol$TestN, ${Cya}Ch+ ${RCol}$RandomCHu, ${Cya}Ch- ${RCol}$RandomCHd, ${Cya}Crashes ${RCol}$TotalCrashCount, ${Cya}CPU Load ${RCol}$LoadCPU, ${Cya}Free RAM ${RCol}${FreeRAM//[[:blank:]]/}, ${Cya}Curr MBF ${RCol}$CurrMBF, ${Cya}Video $Bla$On_Red"CRASH"$RCol, ${Cya}Audio $Bla$On_Red"CRASH"$RCol ";
    echo "--------------------------------------->""$Bla""$On_Red""¡LAUNCHER PORTAL CRASHED!""$RCol""<------------------------------"
    crashLog1=$(logcat -d *:E > ./Crashes/$timestamp1-Portal-Crash.txt)
    echo $Red"$crashLog1"$RCol
    start_time="$(date -u +%s)"
    sleep 10
    logcat -c
    sleep 5
    StartPortalPID=$(pidof com.dotscreen.megacable.portal)
    call_separator
  fi
}

#This function re-launches live tv if livetv was unexpectedly closed.
focus_app() {
  fApp=$(dumpsys window windows | grep -E 'mFocusedApp') #current app
  if [[ $fApp == *"com.dotscreen.megacable.portal"* ]]; then
    echo "LiveTV was unexpectedly closed. Re-launching LiveTV..."
    am start -n com.dotscreen.megacable.livetv/com.dotscreen.tv.MainActivity
    StartLivetvPID=$(pidof com.dotscreen.megacable.livetv)
    call_separator
  fi
  return
}

#Unsubcrived channel, skipes unsubcrived channel by CH+ or Ch-
runUnsubscribe2(){
  if [[ $SubsCH2 == *"261"* ]]; then
    logcat -c
    SubsCH2=0
    if [ "$varCount" -ge 100 ]; then
      input keyevent KEYCODE_CHANNEL_DOWN
    else
      input keyevent KEYCODE_CHANNEL_UP
    fi
    TimeStamp=$(date "+%Y-%m-%d %H:%M:%S") #Update time stamp.
    timestamp1=$(date "+%Y%m%d%H%M%S") #Update timestamp for logs name.
    SubsCH2=$(logcat -d | grep errorCode) 
    sleep 2
  fi
  return
}

runUnsubscribe(){
  while : ; do
    if [[ $SubsCH == *"com.dotscreen.tv.MainActivity#1"* ]]; then 
       logcat -c
       SubsCH=0
       input keyevent KEYCODE_BACK
       if [ "$varCount" -ge 100 ]; then
          input keyevent KEYCODE_CHANNEL_DOWN
       else
          input keyevent KEYCODE_CHANNEL_UP
       fi
       TimeStamp=$(date "+%Y-%m-%d %H:%M:%S") #Update time stamp.
       timestamp1=$(date "+%Y%m%d%H%M%S") #Update timestamp for logs name.
       SubsCH=$(logcat -d | grep duplicate) 
    else
       sleep 2
       return
    fi
  done
}

#This function verifies video
video_check() {
    Vstatus=$(logcat -d | grep setsidebandstream) #Video available?
  if [[ $Vstatus == *"mfbtype=7"* ]]; then
    VResult=$Bla$On_Gre"PASS"$RCol
    VResult1="PASS"
  else
    #mbf_check
    #start_time="$(date -u +%s)"
    VResult=$Bla$On_Red"FAIL"$RCol
    VResult1="FAIL"
    vCount=$(expr $vCount + 1)
  fi
  return
}

#This function verifies audio
audio_check() {
  sleep 1.5
  Astatus=$(logcat -d | grep "dtv_audio_tune_check") #Audio available?
  if [[ $Astatus == *"AUDIO_RUNNING"* ]]; then
    AResult=$Bla$On_Gre"PASS"$RCol
    AResult1="PASS"
  else
    #mbf_check
    #start_time="$(date -u +%s)"
    AResult=$Bla$On_Red"FAIL"$RCol
    AResult1="FAIL"
    aCount=$(expr $aCount + 1)
  fi
  return
}

#Random navigation to the right
movRight() {
  for i in $(seq $RandomRight); do
    input keyevent KEYCODE_DPAD_RIGHT
    sleep .5
  done
  return
}

#Random navigation to the left
movLeft() {
  for i in $(seq $RandomLeft); do
    input keyevent KEYCODE_DPAD_LEFT
    sleep .5
  done
  return
}

#Read CPU and RAM values.
load_check() {
      LoadCPU=$(dumpsys cpuinfo | grep TOTAL | cut -d " " -f1)
      SumCPU=$(expr $SumCPU + ${LoadCPU:0:2})
      AvgCPU=$(expr $SumCPU / $testCount)
      FreeRAM=$(cat /proc/meminfo | grep MemFree | cut -d”:” -f2)
      FreeRAM=$(expr ${FreeRAM:5:12} / 1000)
      SumRAM=$(expr $SumRAM + $FreeRAM)
      AvgRAM=$(expr $SumRAM / $testCount)
      return
      }

#Get meantime between failures
mbf_check() {
      curr_time="$(date -u +%s)"
      MBF="$(($curr_time-$start_time))"
      SumMBF=$(expr $SumMBF + $MBF)
      AvgMBF=$(expr $SumMBF / $TotalCrashCount)
      CurrMBF="$(printf '%02dh:%02dm:%02ds\n' $(($MBF/3600)) $(($MBF%3600/60)) $(($MBF%60)))"
    return
    }

#Display interactions and test results
testResult() {
  echo "${TimeStamp:0:19},$TestN,$RandomCHu,$RandomCHd,$RandomRight,$RandomLeft,$ChannelN,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,$VResult1,$AResult1" >> TestResults;
  echo "${RCol}""${TimeStamp:0:19} ----------------> ${BIBlu}Channel Zapping and banner navigation test${RCol} -----------------> ${Cya}Channel: ${RCol}${ChannelN}
${Cya}TEST# $RCol$TestN, ${Cya}Ch+ ${RCol}$RandomCHu, ${Cya}Ch- ${RCol}$RandomCHd, ${Cya}Crashes ${RCol}$TotalCrashCount, ${Cya}CPU Load ${RCol}$LoadCPU, ${Cya}Free RAM ${RCol}${FreeRAM}MB, ${Cya}Curr MBF ${RCol}$CurrMBF, ${Cya}Video ${RCol}$VResult, ${Cya}Audio ${RCol}$AResult";
  call_separator
  return
} 

start_time="$(date -u +%s)"
main() {
  while : 
  do
    varCount=$(expr $varCount + 1) #Increase counter.
    RandomRight=$((RANDOM % 3))  #Random number for right movements.
    RandomLeft=$((RANDOM % 3)) #Random number for left movements.
    testCount=$(expr $testCount + 1) #Increase test counter.
    TestN=$(printf "%03d" "$testCount") #Counts number of test executed.
    Channel=$(logcat -d | grep displayNumber | grep onZap | cut -d "," -f5 | cut -b16-19) #Update current channel.
    ChannelN=$(printf "%04d" "${Channel:(-4)}")
    SubsCH=$(logcat -d | grep duplicate) 
    SubsCH2=$(logcat -d | grep errorCode)
    TimeStamp=$(date "+%Y-%m-%d %H:%M:%S") #Update time stamp.
    timestamp1=$(date "+%Y%m%d%H%M%S") #Update timestamp for logs name.
    RandomCHd=0; RandomCHu=0; Vstatus=0; Astatus=0 #Resets variable status
    runUnsubscribe; runUnsubscribe2 #Verify if channel requires subscription.
    logcat -c

    if [ "$varCount" -ge 100 ]; then #Verifies counter of variable varCount to cycle 100 times Ch down and 100 times Ch up
      RandomCHd=$((($RANDOM % 7) + 3)) #Random number between 3 and 9 for Channel Down.
      for i in $(seq $RandomCHd); do #Runs channel down for n times.
        input keyevent KEYCODE_CHANNEL_DOWN #Channel down.
        sleep .5
      done
    else
      RandomCHu=$((($RANDOM % 7) + 3)) #Random number between 3 and 9 for Channel Up.
      for i in $(seq $RandomCHu); do #Runs channel up for n times
        input keyevent KEYCODE_CHANNEL_UP 
        sleep .5
      done
    fi
      TimeStamp=$(date "+%Y-%m-%d %H:%M:%S") #Update time stamp.
      timestamp1=$(date "+%Y%m%d%H%M%S") #Update timestamp for logs name.
      sleep 5
      SubsCH=$(logcat -d | grep SurfaceFlinger) 
      SubsCH2=$(logcat -d | grep errorCode) 
      runUnsubscribe #Verify if channel requires subscription.
      runUnsubscribe2
      Channel=$(logcat -d | grep displayNumber | grep onZap | cut -d "," -f5 | cut -b16-19) #Update current channel.
      ChannelN=$(printf "%04d" "${Channel:(-4)}")
      livetv_crash #Verifies if live tv crashed
      portal_crash #Verifies if portal crashed
      dtv_crash #Verify again if dtv crashed.
      multicast_crash #Verify again if multicast crashed.
      sleep .5
      movLeft #Moves to the left in catchup content.
      movRight #Moves to the right in catchup content.
      sleep .5
      video_check #Verify if video is playing.
      audio_check #Verify if audio is playing.
      livetv_crash #Verifies if live tv crashed
      portal_crash #Verifies if portal crashed
      dtv_crash #Verify again if dtv crashed.
      multicast_crash #Verify again if multicast crashed.
      curr_time="$(date -u +%s)"
      MBF="$(($curr_time-$start_time))"
      CurrMBF="$(printf '%02dh:%02dm:%02ds\n' $(($MBF/3600)) $(($MBF%3600/60)) $(($MBF%60)))"
      load_check
      testResult #Prints test results and interactions.
      focus_app #Verifies if live tv is still in foreground.
      run_profiles #If launcher crashes and need to input profile PIN 

    #Every 10 tests, it will perform a manual channel tune of 100, 161 and 204 channels.
    if [ "${TestN:(-1)}" == "9" ]; then
      testCount=$(expr $testCount + 1) #Increase test counter.
      TestN=$(printf "%03d" "$testCount") #Counts number of test executed.
      ManualCh="100 161 204 1000 1161 1204 1212"
      for i in $ManualCh; do
        input text $i
        sleep .5
        input keyevent KEYCODE_DPAD_CENTER
        sleep 5    
      done
      TimeStamp=$(date "+%Y-%m-%d %H:%M:%S") #Update time stamp.
      timestamp1=$(date "+%Y%m%d-%H%M%S") #Update timestamp for logs name.
      curr_time="$(date -u +%s)"
      MBF="$(($curr_time-$start_time))"
      CurrMBF="$(printf '%02dh:%02dm:%02ds\n' $(($MBF/3600)) $(($MBF%3600/60)) $(($MBF%60)))"
      video_check #Verify if video is playing.
      audio_check #Verify if audio is playing.
      livetv_crash #Verifies if live tv crashed
      portal_crash #Verifies if portal crashed
      dtv_crash #Verify again if dtv crashed.
      multicast_crash #Verify again if multicast crashed.
      load_check
      echo "${TimeStamp:0:19},$TestN, , , , ,100 161 204 1000 1161 1204 1212,$TotalCrashCount,$LoadCPU,${FreeRAM//[[:blank:]]/},$CurrMBF,$VResult1,$AResult1" >> TestResults;
      echo "${RCol}""${TimeStamp:0:19} -------------> ${BIBlu} Manual tune of channels 100, 161, 204, 1000, 1161, 1204 & 1212${RCol} 
                ${Cya}TEST #$RCol $TestN, ${Cya}Crashes${RCol} $TotalCrashCount, ${Cya}CPU Load${RCol} $LoadCPU, ${Cya}Free RAM${RCol} ${FreeRAM}MB, ${Cya}Curr MBF${RCol} $CurrMBF, ${Cya}Video${RCol} $VResult, ${Cya}Audio${RCol} $AResult"
      call_separator
      input text "${ChannelN}"; #Backs to previus saved channel by the script
      sleep .5; 
      input keyevent KEYCODE_DPAD_CENTER; 
      sleep 5
    fi

    #Channel change counter
    if [ "$varCount" -ge 200 ]; then
      varCount=0
    fi

    #If Channel reaches the bottom, changes to CH+ cycle
    if [[ $ChannelN -lt 105 ]]; then
      input text "100"
      sleep .5 
      input keyevent KEYCODE_DPAD_CENTER
      varCount=0
    fi

    #If Channel reaches the top, changes to CH- cycle
    if [[ $ChannelN -eq 1702 ]]; then
      varCount=101
    fi
    
    #Finishes script at 100 tests and pull reports
    if [ "${TestN:(-2)}" == "00" ]; then
      echo "$TestN,$vCount,$aCount,$LiveTVcrashCount,$PortalCrashCount,$DtvCrashCount,$MulticastCrashCount,$TotalCrashCount,$AvgCPU"%",$AvgRAM,$AvgMBF" >> InestabilityEvents
    fi
  done
}
main
exit