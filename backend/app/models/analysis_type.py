from sqlmodel import Field, SQLModel


class AnalysisType(SQLModel, table=True):
    __tablename__ = "analysis_types"

    id: str = Field(primary_key=True)
    codigo: str = Field(unique=True, index=True)
    nombre: str
    requiere_descripcion: bool = Field(default=False)
