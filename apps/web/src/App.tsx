import {Routes,Route} from 'react-router';
export function App(){return <Routes><Route path="/" element={<main className="mx-auto max-w-3xl p-10"><h1 className="text-3xl font-bold text-teal-800">CareGap</h1><p className="mt-4">돌봄틈새 팀 프로젝트 개발 환경입니다.</p><p className="mt-2">상담·예약·AI 기능은 API 계약 합의 후 연결합니다.</p></main>}/><Route path="*" element={<main>페이지를 찾을 수 없습니다.</main>}/></Routes>}
