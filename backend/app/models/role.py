import enum


class UserRole(str, enum.Enum):
    ADMIN = "ADMIN"
    OPERARIO = "OPERARIO"
    LABORATORISTA = "LABORATORISTA"

    @classmethod
    def values(cls) -> list[str]:
        return [r.value for r in cls]

    @classmethod
    def is_valid(cls, value: str) -> bool:
        return value in cls.values()