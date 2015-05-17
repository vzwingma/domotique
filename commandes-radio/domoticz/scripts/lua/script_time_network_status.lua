commandArray = {}
print("[FREEBOX] Statuts des périphériques réseau Freebox")

url_api="http://mafreebox.freebox.fr/api/v3/"
os.execute("curl " .. url_api .. "login")

print("[FREEBOX] ")

return commandArray

