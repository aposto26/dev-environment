add-content -path C:/Users/miapos/.ssh/config -value @'

Host ${hostname}
  HostName ${hostname}
  User ${user}
  IdentityFile ${identifyfile}
'@