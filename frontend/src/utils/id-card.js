const WEIGHTS = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
const CHECK_CODES = '10X98765432'

export function validateIdCard(idCard) {
  if (!idCard || idCard.length !== 18) return false
  const body = idCard.substring(0, 17)
  if (!/^\d{17}$/.test(body)) return false
  const check = idCard[17].toUpperCase()
  let total = 0
  for (let i = 0; i < 17; i++) {
    total += parseInt(body[i]) * WEIGHTS[i]
  }
  return check === CHECK_CODES[total % 11]
}

export function extractGender(idCard) {
  if (!idCard || idCard.length < 17) return ''
  return parseInt(idCard[16]) % 2 === 1 ? 'male' : 'female'
}
