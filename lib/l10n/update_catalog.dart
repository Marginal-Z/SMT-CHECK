const updateCatalog = <String, List<String>>{
  '旧版设置迁移失败，原设置已保留，请检查文件权限。': [
    'Legacy settings could not be migrated. Originals are retained; check file permissions.',
    'ไม่สามารถย้ายการตั้งค่าเดิมได้ ไฟล์เดิมยังอยู่ โปรดตรวจสอบสิทธิ์ไฟล์',
  ],
  '在软件内下载并校验安装包，无需打开发布页面。': [
    'Download and verify updates inside the app.',
    'ดาวน์โหลดและตรวจสอบอัปเดตภายในแอป',
  ],
  '下载更新': ['Download update', 'ดาวน์โหลดอัปเดต'],
  '取消下载': ['Cancel download', 'ยกเลิกการดาวน์โหลด'],
  '安装更新': ['Install update', 'ติดตั้งอัปเดต'],
  '重新启动应用': ['Restart app', 'เริ่มแอปใหม่'],
  '正在下载安装包…': ['Downloading update…', 'กำลังดาวน์โหลดอัปเดต…'],
  '正在校验安装包…': ['Verifying update…', 'กำลังตรวจสอบไฟล์อัปเดต…'],
  '正在安装更新，请完成系统授权…': [
    'Installing update. Complete system authorization…',
    'กำลังติดตั้งอัปเดต โปรดอนุญาตผ่านระบบ…',
  ],
  '安装包已通过 SHA-256 校验。': [
    'The installer passed SHA-256 verification.',
    'ไฟล์ติดตั้งผ่านการตรวจสอบ SHA-256 แล้ว',
  ],
  '更新已安装，重新启动后生效。': [
    'Update installed. Restart to apply it.',
    'ติดตั้งอัปเดตแล้ว เริ่มแอปใหม่เพื่อใช้งาน',
  ],
  '安装将关闭并重新启动应用，请先导出需要保留的结果。': [
    'Installation will close and restart the app. Export any results you want to keep first.',
    'การติดตั้งจะปิดและเริ่มแอปใหม่ โปรดส่งออกผลลัพธ์ที่ต้องการเก็บก่อน',
  ],
  '安装需要系统授权；请先导出结果，再安装并重新启动。': [
    'Installation requires system authorization. Export results first, then install and restart.',
    'การติดตั้งต้องได้รับอนุญาตจากระบบ โปรดส่งออกผลลัพธ์ก่อน แล้วติดตั้งและเริ่มใหม่',
  ],
  '下载已取消，可重新下载。': [
    'Download cancelled. You can try again.',
    'ยกเลิกการดาวน์โหลดแล้ว สามารถดาวน์โหลดใหม่ได้',
  ],
  '请等待当前核对、分析或导出任务完成后再安装更新。': [
    'Wait for the current check, analysis or export to finish before installing.',
    'โปรดรอให้การตรวจสอบ วิเคราะห์ หรือส่งออกเสร็จก่อนติดตั้ง',
  ],
  '此安装包缺少有效校验信息或不支持应用内安装，请稍后重试。': [
    'This installer lacks valid verification data or does not support in-app installation. Retry later.',
    'ไฟล์ติดตั้งไม่มีข้อมูลตรวจสอบที่ถูกต้องหรือไม่รองรับการติดตั้งภายในแอป โปรดลองภายหลัง',
  ],
  '安装包校验失败，请重新下载。': [
    'Installer verification failed. Download it again.',
    'ตรวจสอบไฟล์ติดตั้งไม่ผ่าน โปรดดาวน์โหลดใหม่',
  ],
  '安装包大小不符，请重新下载。': [
    'Installer size does not match. Download it again.',
    'ขนาดไฟล์ติดตั้งไม่ตรงกัน โปรดดาวน์โหลดใหม่',
  ],
  '安装包下载失败，请检查网络后重试。': [
    'Download failed. Check your connection and retry.',
    'ดาวน์โหลดไม่สำเร็จ โปรดตรวจสอบเครือข่ายแล้วลองใหม่',
  ],
  '安装包下载超时，请检查网络后重试。': [
    'Download timed out. Check your connection and retry.',
    'หมดเวลาดาวน์โหลด โปรดตรวจสอบเครือข่ายแล้วลองใหม่',
  ],
  '无法写入更新文件，请检查磁盘空间和权限。': [
    'Cannot write the update. Check disk space and permissions.',
    'ไม่สามารถเขียนไฟล์อัปเดตได้ โปรดตรวจสอบพื้นที่ดิสก์และสิทธิ์',
  ],
  '安装包与当前平台不匹配。': [
    'The installer does not match this platform.',
    'ไฟล์ติดตั้งไม่ตรงกับแพลตฟอร์มนี้',
  ],
  '当前平台暂不支持应用内安装。': [
    'In-app installation is not supported on this platform.',
    'แพลตฟอร์มนี้ยังไม่รองรับการติดตั้งภายในแอป',
  ],
  '安装未完成或已取消，请重试并允许系统安装授权。': [
    'Installation failed or was cancelled. Retry and approve the system authorization.',
    'การติดตั้งไม่สำเร็จหรือถูกยกเลิก โปรดลองใหม่และอนุญาตผ่านระบบ',
  ],
  '安装包已丢失或无法读取，请重新下载。': [
    'The installer is missing or unreadable. Download it again.',
    'ไม่พบหรือไม่สามารถอ่านไฟล์ติดตั้งได้ โปรดดาวน์โหลดใหม่',
  ],
  '无法启动系统安装程序，请检查系统权限和安装服务。': [
    'Cannot start the system installer. Check permissions and installer services.',
    'ไม่สามารถเริ่มตัวติดตั้งของระบบได้ โปรดตรวจสอบสิทธิ์และบริการติดตั้ง',
  ],
  '无法重新启动应用，请从系统菜单打开 SMT Fusion。': [
    'Cannot restart the app. Open SMT Fusion from the system menu.',
    'ไม่สามารถเริ่มแอปใหม่ได้ โปรดเปิด SMT Fusion จากเมนูระบบ',
  ],
  '检查更新失败，请稍后重试。': [
    'Update check failed. Please retry later.',
    'ตรวจสอบอัปเดตไม่สำเร็จ โปรดลองภายหลัง',
  ],
  '无法读取当前应用版本，请重新启动应用后重试。': [
    'Cannot read the installed version. Restart the app and retry.',
    'ไม่สามารถอ่านเวอร์ชันที่ติดตั้งได้ โปรดเริ่มแอปใหม่แล้วลองอีกครั้ง',
  ],
  '更新检查暂时受限，请稍后重试。': [
    'Update checks are temporarily rate limited. Retry later.',
    'การตรวจสอบอัปเดตถูกจำกัดชั่วคราว โปรดลองภายหลัง',
  ],
};
