#!/bin/bash

# ============================================
# StudioBook - Midtrans Sandbox Setup Script
# ============================================
#
# Cara penggunaan:
#   chmod +x scripts/setup-midtrans.sh
#   ./scripts/setup-midtrans.sh
#
# Atau langsung jalankan:
#   bash scripts/setup-midtrans.sh
#
# ============================================

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENV_FILE="backend/.env"

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   StudioBook - Midtrans Sandbox Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Cek apakah file .env ada
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: File $ENV_FILE tidak ditemukan!${NC}"
    echo -e "Jalankan script ini dari root project."
    exit 1
fi

echo -e "${YELLOW}Langkah 1: Daftar akun Midtrans Sandbox${NC}"
echo ""
echo "  1. Buka https://account.sandbox.midtrans.com/register"
echo "  2. Isi data diri dan daftar"
echo "  3. Setelah daftar, login ke Dashboard"
echo "  4. Buka menu 'Settings' > 'Access Keys'"
echo "  5. Copy 'Client Key' dan 'Server Key'"
echo ""

# Minta input dari user
echo -e "${YELLOW}Langkah 2: Masukkan Access Keys${NC}"
echo ""

read -p "  Client Key (SB-Mid-client-xxxx): " CLIENT_KEY
read -p "  Server Key (SB-Mid-server-xxxx): " SERVER_KEY
read -p "  Merchant ID (optional, tekan Enter untuk skip): " MERCHANT_ID

# Validasi input
if [ -z "$CLIENT_KEY" ] || [ -z "$SERVER_KEY" ]; then
    echo ""
    echo -e "${RED}Error: Client Key dan Server Key wajib diisi!${NC}"
    exit 1
fi

# Validasi format key
if [[ ! "$CLIENT_KEY" == SB-Mid-client-* ]]; then
    echo ""
    echo -e "${YELLOW}Warning: Client Key sepertinya bukan sandbox key (seharusnya SB-Mid-client-xxx)${NC}"
    read -p "  Lanjutkan? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Dibatalkan."
        exit 0
    fi
fi

if [[ ! "$SERVER_KEY" == SB-Mid-server-* ]]; then
    echo ""
    echo -e "${YELLOW}Warning: Server Key sepertinya bukan sandbox key (seharusnya SB-Mid-server-xxx)${NC}"
    read -p "  Lanjutkan? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Dibatalkan."
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}Langkah 3: Update file .env${NC}"
echo ""

# Backup file .env
cp "$ENV_FILE" "${ENV_FILE}.backup"
echo -e "  ${GREEN}✓ Backup .env → .env.backup${NC}"

# Update MIDTRANS_CLIENT_KEY
if grep -q "^MIDTRANS_CLIENT_KEY=" "$ENV_FILE"; then
    sed -i "s|^MIDTRANS_CLIENT_KEY=.*|MIDTRANS_CLIENT_KEY=${CLIENT_KEY}|" "$ENV_FILE"
else
    echo "MIDTRANS_CLIENT_KEY=${CLIENT_KEY}" >> "$ENV_FILE"
fi
echo -e "  ${GREEN}✓ MIDTRANS_CLIENT_KEY updated${NC}"

# Update MIDTRANS_SERVER_KEY
if grep -q "^MIDTRANS_SERVER_KEY=" "$ENV_FILE"; then
    sed -i "s|^MIDTRANS_SERVER_KEY=.*|MIDTRANS_SERVER_KEY=${SERVER_KEY}|" "$ENV_FILE"
else
    echo "MIDTRANS_SERVER_KEY=${SERVER_KEY}" >> "$ENV_FILE"
fi
echo -e "  ${GREEN}✓ MIDTRANS_SERVER_KEY updated${NC}"

# Update MIDTRANS_MERCHANT_ID if provided
if [ ! -z "$MERCHANT_ID" ]; then
    if grep -q "^MIDTRANS_MERCHANT_ID=" "$ENV_FILE"; then
        sed -i "s|^MIDTRANS_MERCHANT_ID=.*|MIDTRANS_MERCHANT_ID=${MERCHANT_ID}|" "$ENV_FILE"
    else
        echo "MIDTRANS_MERCHANT_ID=${MERCHANT_ID}" >> "$ENV_FILE"
    fi
    echo -e "  ${GREEN}✓ MIDTRANS_MERCHANT_ID updated${NC}"
fi

# Pastikan MIDTRANS_IS_PRODUCTION=false (sandbox mode)
if grep -q "^MIDTRANS_IS_PRODUCTION=" "$ENV_FILE"; then
    sed -i "s|^MIDTRANS_IS_PRODUCTION=.*|MIDTRANS_IS_PRODUCTION=false|" "$ENV_FILE"
else
    echo "MIDTRANS_IS_PRODUCTION=false" >> "$ENV_FILE"
fi
echo -e "  ${GREEN}✓ MIDTRANS_IS_PRODUCTION=false (sandbox mode)${NC}"

# Update MIDTRANS_WEBHOOK_URL
APP_URL=$(grep "^APP_URL=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
WEBHOOK_URL="${APP_URL}/api/v1/payments/webhook/midtrans"

if grep -q "^MIDTRANS_WEBHOOK_URL=" "$ENV_FILE"; then
    sed -i "s|^MIDTRANS_WEBHOOK_URL=.*|MIDTRANS_WEBHOOK_URL=${WEBHOOK_URL}|" "$ENV_FILE"
else
    echo "MIDTRANS_WEBHOOK_URL=${WEBHOOK_URL}" >> "$ENV_FILE"
fi
echo -e "  ${GREEN}✓ MIDTRANS_WEBHOOK_URL = ${WEBHOOK_URL}${NC}"

# Tambahkan VITE env untuk frontend
VITE_ENV_FILE="web/.env"
echo ""

# Update atau buat web/.env untuk VITE Midtrans keys
if [ -f "$VITE_ENV_FILE" ]; then
    # Update existing
    if grep -q "VITE_MIDTRANS_SNAP_URL" "$VITE_ENV_FILE"; then
        sed -i "s|^VITE_MIDTRANS_SNAP_URL=.*|VITE_MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/snap.js|" "$VITE_ENV_FILE"
    else
        echo "VITE_MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/snap.js" >> "$VITE_ENV_FILE"
    fi

    if grep -q "VITE_MIDTRANS_CLIENT_KEY" "$VITE_ENV_FILE"; then
        sed -i "s|^VITE_MIDTRANS_CLIENT_KEY=.*|VITE_MIDTRANS_CLIENT_KEY=${CLIENT_KEY}|" "$VITE_ENV_FILE"
    else
        echo "VITE_MIDTRANS_CLIENT_KEY=${CLIENT_KEY}" >> "$VITE_ENV_FILE"
    fi
else
    cat > "$VITE_ENV_FILE" << EOF
VITE_MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/snap.js
VITE_MIDTRANS_CLIENT_KEY=${CLIENT_KEY}
EOF
fi
echo -e "  ${GREEN}✓ web/.env updated (VITE Midtrans keys)${NC}"

echo ""
echo -e "${YELLOW}Langkah 4: Setup Webhook di Midtrans Dashboard${NC}"
echo ""
echo "  Untuk menerima notifikasi pembayaran, tambahkan webhook URL:"
echo ""
echo -e "  ${GREEN}${WEBHOOK_URL}${NC}"
echo ""
echo "  Caranya:"
echo "  1. Login ke https://account.sandbox.midtrans.com/login"
echo "  2. Buka menu 'Settings' > 'Set Webhook URL'"
echo "  3. Masukkan URL di atas"
echo "  4. Klik 'Save'"
echo ""

# ============================================
# Cara testing dengan Midtrans Test Cards
# ============================================
echo -e "${YELLOW}Langkah 5: Cara Testing Pembayaran${NC}"
echo ""
echo "  Gunakan kartu kredit test berikut:"
echo ""
echo "  ${GREEN}Kartu Kredit (Berhasil):${NC}"
echo "    Nomor    : 4811 1111 1111 1114"
echo "    CVV      : 123"
echo "    Expired  : 12/25"
echo "    Nama     : ANY"
echo ""
echo "  ${GREEN}Kartu Kredit (Gagal):${NC}"
echo "    Nomor    : 4811 1111 1111 1118"
echo "    CVV      : 123"
echo "    Expired  : 12/25"
echo ""
echo "  ${GREEN}GoPay (Berhasil):${NC}"
echo "    Phone    : 081111111111"
echo "    OTP      : 123456"
echo ""
echo "  ${GREEN}BCA VA (Berhasil):${NC}"
echo "    Nomor VA : 1234567890"
echo ""
echo "  ${GREEN}Mandiri VA:${NC}"
echo "    Nomor VA : 1234567890123"
echo ""
echo "  Dokumentasi lengkap: https://docs.midtrans.com/docs/sandbox-testing"
echo ""

# ============================================
# Verifikasi Konfigurasi
# ============================================
echo -e "${YELLOW}Verifikasi Konfigurasi:${NC}"
echo ""

# Cek backend .env
echo -e "  ${BLUE}Backend (.env):${NC}"
grep "^MIDTRANS_" "$ENV_FILE" | while read line; do
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2)
    if [ ! -z "$value" ]; then
        # Sembunyikan server key untuk keamanan
        if [[ "$key" == *"SERVER_KEY"* ]]; then
            masked="${value:0:15}...${value: -4}"
            echo -e "    ${GREEN}✓${NC} $key = $masked"
        else
            echo -e "    ${GREEN}✓${NC} $key = $value"
        fi
    else
        echo -e "    ${RED}✗${NC} $key = (kosong)"
    fi
done

echo ""
echo -e "  ${BLUE}Frontend (web/.env):${NC}"
if [ -f "$VITE_ENV_FILE" ]; then
    grep "^VITE_MIDTRANS" "$VITE_ENV_FILE" | while read line; do
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2)
        if [ ! -z "$value" ]; then
            echo -e "    ${GREEN}✓${NC} $key = $value"
        else
            echo -e "    ${RED}✗${NC} $key = (kosong)"
        fi
    done
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Setup Midtrans Sandbox Selesai! 🎉${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Restart backend server:"
echo "    cd backend && php artisan serve"
echo ""
echo "  Restart frontend:"
echo "    cd web && npm run dev"
echo ""
echo "  Test pembayaran:"
echo "    1. Login sebagai customer@studiobook.com"
echo "    2. Pilih studio → pilih ruangan → booking"
echo "    3. Pada halaman pembayaran, pilih metode"
echo "    4. Gunakan kartu test di atas"
echo ""
