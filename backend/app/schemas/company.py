from pydantic import BaseModel


class CompanyCreate(BaseModel):
    name: str


class CompanyOut(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}


class ProjectCreate(BaseModel):
    name: str
    company_id: int | None = None


class ProjectOut(BaseModel):
    id: int
    name: str
    company_id: int | None = None
    company_name: str | None = None

    model_config = {"from_attributes": True}
