const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.user.findMany({ select: { email: true, role: true, id: true }, take: 10 })
  .then(users => { console.log(JSON.stringify(users, null, 2)); })
  .finally(() => p.$disconnect());
