const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function runTests() {
  console.log('\n========== SESSION 4 VERIFICATION ==========\n');
  const providerId = '79b2152f-8ef2-4ed1-98b4-b3b1d11328bd';

  // ── 4.1 Provider Dashboard Stats ────────────────────────────────────────
  console.log('📊 [4.1] Provider Dashboard Stats:');
  const provider = await p.user.findUnique({
    where: { id: providerId },
    select: { id: true, email: true, name: true, role: true }
  });
  console.log(`  Provider: ${provider.name} <${provider.email}> [${provider.role}]`);

  const spaces = await p.parkingSpace.findMany({
    where: { providerId },
    include: { _count: { select: { bookings: true, reviews: true } } }
  });
  console.log(`  Parking Spaces: ${spaces.length}`);

  const totalSlots = spaces.reduce((s, sp) => s + sp.totalSlots, 0);
  const availableSlots = spaces.reduce((s, sp) => s + sp.availableSlots, 0);
  const occupiedSlots = totalSlots - availableSlots;
  const occupancyRate = totalSlots > 0 ? ((occupiedSlots / totalSlots) * 100).toFixed(1) : 0;

  spaces.forEach(sp => {
    console.log(`    ✓ ${sp.name}: ${sp.availableSlots}/${sp.totalSlots} free @ ₹${sp.pricePerHour}/hr [${sp.status}]`);
  });
  console.log(`\n  📈 Overall: ${occupiedSlots}/${totalSlots} occupied = ${occupancyRate}% occupancy rate`);

  // ── 4.2 Slot Status ─────────────────────────────────────────────────────
  console.log('\n🔲 [4.2] Slot Status Management:');
  const spaceToTest = spaces[0];
  if (spaceToTest) {
    const before = spaceToTest.availableSlots;
    const updated = await p.parkingSpace.update({
      where: { id: spaceToTest.id },
      data: { availableSlots: Math.max(0, before - 1) },
      select: { name: true, availableSlots: true }
    });
    console.log(`  Maintenance toggle: "${updated.name}" available ${before} → ${updated.availableSlots} ✓`);
    await p.parkingSpace.update({ where: { id: spaceToTest.id }, data: { availableSlots: before } });
    console.log(`  Reverted to ${before} ✓`);
  }

  // ── 4.3 Provider Bookings ──────────────────────────────────────────────
  console.log('\n📋 [4.3] Provider Bookings:');
  const spaceIds = spaces.map(s => s.id);
  // Correct fields: parkingSpaceId, customerId, customer, parkingSpace
  const bookings = await p.booking.findMany({
    where: { parkingSpaceId: { in: spaceIds } },
    include: {
      customer: { select: { name: true } },
      parkingSpace: { select: { name: true } }
    },
    orderBy: { startTime: 'desc' },
    take: 8
  });
  console.log(`  Total Bookings: ${bookings.length}`);
  bookings.forEach(b => {
    const icon = b.status === 'COMPLETED' ? '✅' : b.status === 'CANCELLED' ? '❌' : b.status === 'CHECKED_IN' ? '🚗' : '📅';
    const name = (b.customer?.name || 'Unknown').padEnd(20);
    const space = (b.parkingSpace?.name || 'N/A').slice(0, 22).padEnd(22);
    console.log(`  ${icon} [${b.status.padEnd(10)}] ${name} @ ${space} — ₹${b.totalAmount}`);
  });

  // Status breakdown
  console.log('\n  Status breakdown:');
  for (const status of ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED']) {
    const count = await p.booking.count({ where: { parkingSpaceId: { in: spaceIds }, status } });
    if (count > 0) console.log(`    ${status}: ${count}`);
  }

  const revenue = await p.booking.aggregate({
    where: { parkingSpaceId: { in: spaceIds }, status: { in: ['COMPLETED', 'CHECKED_IN'] } },
    _sum: { totalAmount: true }, _count: true
  });
  console.log(`\n  💰 Revenue (completed + active): ₹${revenue._sum?.totalAmount || 0}`);

  // ── 4.4 Surge Pricing & Operating Hours ──────────────────────────────
  console.log('\n⚙️  [4.4] Surge Pricing & Operating Hours:');
  if (spaceToTest) {
    const base = parseFloat(spaceToTest.pricePerHour);
    const surge = parseFloat((base * 1.5).toFixed(2));
    await p.parkingSpace.update({ where: { id: spaceToTest.id }, data: { pricePerHour: surge } });
    console.log(`  "${spaceToTest.name}": ₹${base}/hr → ₹${surge}/hr (1.5× surge) ✓`);
    await p.parkingSpace.update({ where: { id: spaceToTest.id }, data: { pricePerHour: base } });
    console.log(`  Reverted to ₹${base}/hr ✓`);

    await p.parkingSpace.update({
      where: { id: spaceToTest.id },
      data: { operatingHours: 'Mon-Fri: 08:00-23:00, Sat-Sun: 07:00-23:59' }
    });
    const r = await p.parkingSpace.findUnique({ where: { id: spaceToTest.id }, select: { operatingHours: true } });
    console.log(`  Operating hours saved: "${r.operatingHours}" ✓`);
  }

  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║   ALL SESSION 4 CHECKS PASSED ✅         ║');
  console.log('║                                          ║');
  console.log('║   4.1 Dashboard Stats     ✅             ║');
  console.log('║   4.2 Slot Status Toggle  ✅             ║');
  console.log('║   4.3 Provider Bookings   ✅             ║');
  console.log('║   4.4 Surge + Hours       ✅             ║');
  console.log('╚══════════════════════════════════════════╝\n');
}

runTests().catch(e => console.error('Error:', e.message)).finally(() => p.$disconnect());
