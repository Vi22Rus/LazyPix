LazyG 0.8.20 TEST — Healbot cooldown detection

Исправлена проверка готовности Health Potion/Healthstone в HealthWidget.lua:
сначала C_Spell.GetItemCooldown(id).isActive (NeverSecret), затем резервная
проверка числовых времён C_Container.GetItemCooldown.
Если оба способа недоступны, предмет остаётся серым во избежание
ложной индикации доступности.

/lazyg status показывает ID предмета, видимость HP, готовность и API-источник
проверки кулдауна. Светофор, аддоны ротаций и GCD не изменены.

Проверить в WoW Forever при здоровье выше и ниже порога, когда предмет
готов и когда находится на кулдауне; затем /lazyg status.
