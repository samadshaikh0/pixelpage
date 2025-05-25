import json
import base64
import qrcode
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend


key = b'SaRuAbShKhBa1234'       
iv  = b'InitVector123456'       


def encrypt_qr_data(book_id, qr_id):
    # 1. Create JSON payload
    payload = json.dumps({
        "bookId": book_id,
        "qrId": qr_id
    }).encode('utf-8')

    # 2. Pad the payload
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(payload) + padder.finalize()

    # 3. Encrypt using AES-CBC
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    encrypted = encryptor.update(padded_data) + encryptor.finalize()

    # 4. Encode to Base64 for QR use
    return base64.b64encode(encrypted).decode('utf-8')

def generate_qr_code(data, filename='encrypted_qr.png'):
    qr = qrcode.QRCode(
        version=1, box_size=10, border=4,
        error_correction=qrcode.constants.ERROR_CORRECT_H
    )
    qr.add_data(data)
    qr.make(fit=True)

    img = qr.make_image(fill='black', back_color='white')
    img.save(filename)
    print(f'✅ QR code saved as {filename}')

# 🧪 Example usage
if __name__ == '__main__':
    encrypted_data = encrypt_qr_data("BK01", "SUBJ08")
    print(f"Encrypted QR data:\n{encrypted_data}")
    generate_qr_code(encrypted_data)
