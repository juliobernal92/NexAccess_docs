import React, { useState } from 'react';
import { ScrollView, Text, TextInput, useWindowDimensions, View } from 'react-native';
import { Screen, pagePadding } from '../../components/Screen';
import { Button, Chips, Empty, Icon } from '../../components/ui';
import { useUsers } from '../../state/UsersProvider';
import { normalize } from '../../domain/users';
import EventList from './EventList';
import { colors, ui } from '../../theme';

export default function History() {
  const { width } = useWindowDimensions();
  const { users, events, settings } = useUsers();
  const [search, setSearch] = useState('');
  const [result, setResult] = useState('Todos');
  const [page, setPage] = useState(1);
  const filtered = events.filter(e => {
    const user = users.find(u => u.id === e.employeeId);
    return normalize(`${user?.nombre ?? ''} ${user?.apellido ?? ''} ${e.area} ${e.id}`).includes(normalize(search)) && (result === 'Todos' || (e.resultado === 'AUTORIZADO') === (result === 'Permitidos'));
  });
  const pages = Math.max(1, Math.ceil(filtered.length / settings.pageSize));
  return <Screen section="Historial de accesos"><ScrollView contentContainerStyle={{ padding: pagePadding(width), maxWidth: 1100, width: '100%', alignSelf: 'center', gap: 22 }}>
    <View style={{ gap: 8 }}><Text style={[ui.label, { color: colors.primary, letterSpacing: 2, fontSize: 11 }]}>ACTIVIDAD / CONSULTA</Text><Text style={ui.title}>Historial de accesos</Text><Text style={ui.muted}>Consultá los intentos de ingreso de las personas registradas.</Text></View>
    <View style={ui.card}><View style={[ui.row, ui.input, { paddingVertical: 0 }]}><Icon name="search-outline" /><TextInput accessibilityLabel="Buscar accesos" value={search} onChangeText={v => { setSearch(v); setPage(1); }} placeholder="Buscar por persona, área o evento" placeholderTextColor={colors.muted} style={{ flex: 1, minWidth: 0, minHeight: 48, fontSize: 14, color: colors.text }} /></View><Chips options={['Todos', 'Permitidos', 'Denegados']} selected={result} onChange={v => { setResult(v); setPage(1); }} /><Text style={ui.muted}>{filtered.length} eventos de demostración · Zona horaria: {settings.timezone}</Text></View>
    {filtered.length ? <EventList events={filtered.slice((page - 1) * settings.pageSize, page * settings.pageSize)} /> : <View style={ui.card}><Empty title="No encontramos accesos" description="Revisá la búsqueda y los filtros." action={<Button title="Limpiar filtros" variant="secondary" onPress={() => { setSearch(''); setResult('Todos'); setPage(1); }} />} /></View>}
    <View style={[ui.wrap, { justifyContent: 'space-between' }]}><Text style={ui.muted}>Página {page} de {pages}</Text><View style={ui.row}><Button title="Anterior" variant="secondary" disabled={page === 1} onPress={() => setPage(page - 1)} /><Button title="Siguiente" variant="secondary" disabled={page === pages} onPress={() => setPage(page + 1)} /></View></View>
    <Text style={ui.muted}>Los eventos son de solo lectura y no representan marcaciones de asistencia.</Text>
  </ScrollView></Screen>;
}
