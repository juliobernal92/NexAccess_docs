import React, { createContext, useContext, useEffect, useState } from 'react';
import { Employee, EmployeeDraft } from '../domain/types';
import { employees, events } from '../data/mock';
import { cleanDraft, validateDraft } from '../domain/users';
import { useSystemState } from './useSystemState';

type Store = ReturnType<typeof useSystemState> & { users: Employee[]; events: typeof events; notice: string; save: (draft: EmployeeDraft, id?: string) => string; toggle: (id: string) => void; dismiss: () => void };
const Context = createContext<Store | null>(null);
export function UsersProvider({ children }: React.PropsWithChildren) {
  const [users, setUsers] = useState<Employee[]>(employees);
  const [notice, setNotice] = useState('');
  const system = useSystemState(users, setNotice);
  useEffect(() => { if (!notice) return; const timer = setTimeout(() => setNotice(''), 6000); return () => clearTimeout(timer); }, [notice]);
  function save(draft: EmployeeDraft, id?: string) {
    if (Object.keys(validateDraft(draft, users, id)).length) throw new Error('El formulario contiene errores.');
    const value = cleanDraft(draft);
    if (id && !users.some(u => u.id === id)) throw new Error('El usuario no existe.');
    const resultId = id ?? `EMP-${String(Math.max(0, ...users.map(u => Number(u.id.split('-')[1]))) + 1).padStart(3, '0')}`;
    setUsers(current => id ? current.map(u => u.id === id ? { ...u, ...value } : u) : [{ ...value, id: resultId, createdAt: new Date().toISOString() }, ...current]);
    setNotice(id ? 'Información del usuario actualizada.' : 'Usuario registrado correctamente.');
    system.auditAction(id ? 'Usuario modificado' : 'Usuario creado', 'Usuarios', resultId, `${value.nombre} ${value.apellido}: ${id ? 'información actualizada' : 'alta registrada'}.`);
    return resultId;
  }
  function toggle(id: string) {
    const user = users.find(u => u.id === id);
    if (!user) return;
    setUsers(current => current.map(u => u.id === id ? { ...u, activo: !u.activo } : u));
    setNotice(user.activo ? 'Usuario desactivado en la demostración.' : 'Usuario activado en la demostración.');
    system.auditAction(user.activo ? 'Usuario desactivado' : 'Usuario activado', 'Usuarios', id, `Cambio de estado de ${user.nombre} ${user.apellido}.`);
  }
  return <Context.Provider value={{ ...system, users, events, notice, save, toggle, dismiss: () => setNotice('') }}>{children}</Context.Provider>;
}
export function useUsers() { const store = useContext(Context); if (!store) throw new Error('Falta UsersProvider'); return store; }
