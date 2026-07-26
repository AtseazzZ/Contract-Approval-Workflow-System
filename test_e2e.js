const http = require('http');

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    if (token) headers['Authorization'] = 'Bearer ' + token;
    const req = http.request({ hostname: 'localhost', port: 8081, path: '/api' + path, method, headers }, (res) => {
      let respBody = '';
      res.on('data', c => respBody += c);
      res.on('end', () => resolve({ status: res.statusCode, body: respBody }));
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function login(u) {
  const r = await request('POST', '/auth/login', { username: u, password: '123456' });
  return JSON.parse(r.body).data;
}

(async () => {
  console.log('===== 1. 数据范围测试 (Data Scope) =====');
  const tokens = {};
  const labels = { u1: 'SELF(仅本人)', u2: 'CUSTOM(研发+市场)', u3: 'DEPT(研发部)', u4: 'ALL(全部)' };
  for (const u of ['u1','u2','u3','u4']) {
    const info = await login(u);
    tokens[u] = info.token;
    const list = await request('GET', '/contract/list?page=1&size=20', null, tokens[u]);
    const data = JSON.parse(list.body);
    const records = data.data && data.data.records ? data.data.records : [];
    const deptIds = records.map(r => r.deptId).join(',');
    const applicantIds = records.map(r => r.applicantId).join(',');
    console.log(`[${u}] ${labels[u]} perms=[${info.permissions.join(',')}] -> ${records.length}条, deptIds=[${deptIds}], applicantIds=[${applicantIds}]`);
  }

  console.log('\n===== 2. IDOR 防护测试 =====');
  // U3(研发部经理) 查看合同5(市场部) → 应404
  const idor = await request('GET', '/contract/5', null, tokens.u3);
  console.log(`U3 查看合同5(市场部,超出DEPT范围): status=${idor.status} body=${idor.body.substring(0,80)}`);
  // U3 查看合同1(研发部) → 应200
  const ok = await request('GET', '/contract/1', null, tokens.u3);
  console.log(`U3 查看合同1(研发部,DEPT范围内): status=${ok.status}`);

  console.log('\n===== 3. 字段可见性测试 =====');
  // 合同2 PENDING_MANAGER → bank_account应脱敏
  const d2 = await request('GET', '/contract/2', null, tokens.u2);
  const c2 = JSON.parse(d2.body);
  if (c2.data) console.log(`合同2(PENDING_MANAGER): bankAccount=${c2.data.bankAccount} (应脱敏 62****10)`);
  // 合同3 PENDING_LEADER → clause_detail/attachment/remark应null, bank_account脱敏
  const d3 = await request('GET', '/contract/3', null, tokens.u4);
  const c3 = JSON.parse(d3.body);
  if (c3.data) console.log(`合同3(PENDING_LEADER): bankAccount=${c3.data.bankAccount} clauseDetail=${c3.data.clauseDetail} attachment=${c3.data.attachment} remark=${c3.data.remark} (应: 脱敏/null/null/null)`);

  console.log('\n===== 4. 按钮可见性(权限)测试 =====');
  const u1info = await login('u1');
  const u4info = await login('u4');
  console.log(`U1(申请人) perms: [${u1info.permissions.join(',')}] -> 有create/view/edit/withdraw, 无approve/process/delete/audit`);
  console.log(`U4(领导) perms: [${u4info.permissions.join(',')}] -> 有approve/delete/audit(继承DEPT_MANAGER的approve)`);

  console.log('\n===== 5. 审批流测试: U1提交→U2处理→U3审批→U4审批 =====');
  // 合同4 DRAFT → U1 SUBMIT → PENDING_ADMIN
  let r = await request('POST', '/contract/4/submit?comment=U1-submit', null, tokens.u1);
  console.log(`U1 SUBMIT 合同4: ${r.status} ${r.body.substring(0,80)}`);
  // U2 PROCESS → PENDING_MANAGER
  r = await request('POST', '/contract/4/process?comment=U2-process', null, tokens.u2);
  console.log(`U2 PROCESS 合同4: ${r.status} ${r.body.substring(0,80)}`);
  // U3 APPROVE → PENDING_LEADER
  r = await request('POST', '/contract/4/approve?comment=U3-approve', null, tokens.u3);
  console.log(`U3 APPROVE 合同4: ${r.status} ${r.body.substring(0,80)}`);
  // U4 APPROVE → APPROVED
  r = await request('POST', '/contract/4/approve?comment=U4-final', null, tokens.u4);
  console.log(`U4 APPROVE 合同4: ${r.status} ${r.body.substring(0,80)}`);

  console.log('\n===== 6. 节点顺序测试: U3不能跳过U2 =====');
  // 合同1 PENDING_ADMIN, U3直接APPROVE → 应403
  r = await request('POST', '/contract/1/approve?comment=U3-skip', null, tokens.u3);
  console.log(`U3 对PENDING_ADMIN合同APPROVE(应403): ${r.status} ${r.body.substring(0,80)}`);

  console.log('\n===== 7. 审计日志测试 =====');
  // U4 查看
  r = await request('GET', '/audit/list?page=1&size=10', null, tokens.u4);
  const auditData = JSON.parse(r.body);
  const auditRecords = auditData.data && auditData.data.records ? auditData.data.records : [];
  console.log(`U4 查看审计日志: status=${r.status} 共${auditRecords.length}条`);
  // U1 无权限 → 403
  r = await request('GET', '/audit/list?page=1&size=10', null, tokens.u1);
  console.log(`U1 查看审计日志(应403): ${r.status} ${r.body.substring(0,80)}`);

  console.log('\n===== 8. 角色继承测试: U4(LEADER)应继承DEPT_MANAGER权限 =====');
  // U4 应有 contract:approve (来自LEADER) 且继承DEPT_MANAGER的approve
  console.log(`U4 roles: [${u4info.roles.join(',')}] 应包含LEADER`);
  console.log(`U4 permissions含contract:approve: ${u4info.permissions.includes('contract:approve')}`);

  console.log('\n===== 测试完成 =====');
})().catch(e => console.error('ERROR:', e));
